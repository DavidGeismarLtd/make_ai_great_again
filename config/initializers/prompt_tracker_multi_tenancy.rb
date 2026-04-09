# frozen_string_literal: true

# Configure PromptTracker models with multi-tenancy support
#
# This initializer adds acts_as_tenant to all PromptTracker models to ensure
# complete data isolation between organizations. Each model will automatically:
# - Add belongs_to :organization association
# - Add default_scope to filter by current tenant
# - Add validation to prevent cross-tenant associations
#
# The to_prepare block ensures this runs after the engine is loaded and
# reloads in development mode when code changes.

Rails.application.config.to_prepare do
  # Configure acts_as_tenant for PromptTracker models
  # We need to explicitly require each model and then configure it

  # List of PromptTracker models that have organization_id
  # Note: All these models have organization_id added via migration
  # (see db/migrate/20260225100645_add_organization_id_to_prompt_tracker_tables.rb)
  models_to_configure = %w[
    agent
    agent_version
    test
    test_run
    prompt_test_suite
    prompt_test_suite_run
    dataset
    dataset_row
    evaluation
    evaluator_config
    human_evaluation
    llm_response
    trace
    span
    ab_test
    function_definition
    environment_variable
    deployed_agent
    agent_conversation
    task_run
    task_schedule
    function_execution
  ]

  models_to_configure.each do |model_file|
    begin
      # Get the model class (this will autoload it if needed)
      model_class = "PromptTracker::#{model_file.camelize}".constantize

      # Skip if already configured (check for organization association added by acts_as_tenant)
      if model_class.reflect_on_association(:organization)&.options&.dig(:inverse_of) == :acts_as_tenant
        Rails.logger.debug "⏭ Skipping PromptTracker::#{model_file.camelize} (already configured)"
        next
      end

      # Check if the model has an organization_id column
      unless model_class.column_names.include?("organization_id")
        Rails.logger.debug "⏭ Skipping PromptTracker::#{model_file.camelize} (no organization_id column)"
        next
      end

      # Add acts_as_tenant using send to avoid reopening the class
      # This preserves all existing methods including private ones
      model_class.acts_as_tenant :organization

      Rails.logger.info "✓ Configured acts_as_tenant for PromptTracker::#{model_file.camelize}"
    rescue LoadError => e
      Rails.logger.warn "⚠ Could not load PromptTracker::#{model_file.camelize}: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "✗ Error configuring PromptTracker::#{model_file.camelize}: #{e.message}"
    end
  end

  # Fix uniqueness validations to be tenant-scoped
  # The PromptTracker gem uses standard validates :uniqueness which doesn't work
  # properly with acts_as_tenant. We need to replace them with validates_uniqueness_to_tenant.
  #
  # Strategy: Use clear_validators! to remove all validations, then re-add them with tenant-scoped uniqueness.
  begin
    # PromptTracker::Agent - fix slug and name uniqueness
    PromptTracker::Agent.class_eval do
      # Clear ALL validators and callbacks
      clear_validators!

      # Re-add all the validations from the gem, but with tenant-scoped uniqueness
      validates :name, presence: true
      validates :slug, presence: true, format: { with: /\A[a-z0-9_]+\z/, message: "must contain only lowercase letters, numbers, and underscores" }

      # Add tenant-scoped uniqueness validations (instead of global ones)
      validates_uniqueness_to_tenant :slug, case_sensitive: false
      validates_uniqueness_to_tenant :name
    end
    Rails.logger.info "✓ Fixed uniqueness validations for PromptTracker::Agent"
  rescue StandardError => e
    Rails.logger.error "✗ Error fixing PromptTracker::Agent validations: #{e.message}"
  end

  begin
    # PromptTracker::Dataset - fix name uniqueness
    PromptTracker::Dataset.class_eval do
      # Clear ALL validators and callbacks
      clear_validators!

      # Re-add all validations with tenant-scoped uniqueness
      validates :name, presence: true
      validates :testable, presence: true
      validates :schema, presence: true

      validate :schema_must_be_array
      validate :schema_matches_testable

      # Add tenant-scoped uniqueness validation (instead of global)
      validates_uniqueness_to_tenant :name, scope: [ :testable_type, :testable_id ]
    end
    Rails.logger.info "✓ Fixed uniqueness validations for PromptTracker::Dataset"
  rescue StandardError => e
    Rails.logger.error "✗ Error fixing PromptTracker::Dataset validations: #{e.message}"
  end

  begin
    # PromptTracker::EvaluatorConfig - fix evaluator_type uniqueness
    PromptTracker::EvaluatorConfig.class_eval do
      # Clear ALL validators and callbacks
      clear_validators!

      # Re-add all validations with tenant-scoped uniqueness
      validates :evaluator_type, presence: true
      validate :evaluator_compatible_with_testable

      # Add tenant-scoped uniqueness validation (instead of global)
      validates_uniqueness_to_tenant :evaluator_type, scope: [ :configurable_type, :configurable_id ]
    end
    Rails.logger.info "✓ Fixed uniqueness validations for PromptTracker::EvaluatorConfig"
  rescue StandardError => e
    Rails.logger.error "✗ Error fixing PromptTracker::EvaluatorConfig validations: #{e.message}"
  end

  # PromptTracker::LlmResponse - make agent_version_id and rendered_prompt optional
  # The gem requires both, but the Monitoring API allows external SDK calls without an agent.
  begin
    PromptTracker::LlmResponse.class_eval do
      # Re-declare agent_version as optional (gem declares it as required belongs_to)
      belongs_to :agent_version,
                 class_name: "PromptTracker::AgentVersion",
                 inverse_of: :llm_responses,
                 optional: true

      # Remove presence validators for :rendered_prompt and :agent_version
      # The original belongs_to adds a presence validator for agent_version,
      # and the gem adds validates :rendered_prompt, presence: true
      %i[rendered_prompt agent_version].each do |attr|
        _validators[attr]&.reject! { |v| v.is_a?(ActiveModel::Validations::PresenceValidator) }
      end

      # Remove the actual validate callbacks for these attributes
      _validate_callbacks.each do |callback|
        filter = callback.filter
        next unless filter.is_a?(ActiveModel::Validations::PresenceValidator)
        next unless (filter.attributes & [ :rendered_prompt, :agent_version ]).any?

        _validate_callbacks.delete(callback)
      end
    end
    Rails.logger.info "✓ Made agent_version and rendered_prompt optional on PromptTracker::LlmResponse"
  rescue StandardError => e
    Rails.logger.error "✗ Error configuring PromptTracker::LlmResponse: #{e.message}"
  end
end
