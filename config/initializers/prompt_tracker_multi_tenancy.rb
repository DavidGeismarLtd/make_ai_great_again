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
  # Note: Evaluation is excluded because it doesn't have organization_id
  # (it's scoped through llm_response or test_run associations)
  models_to_configure = %w[
    prompt
    prompt_version
    test
    test_run
    dataset
    dataset_row
    evaluator_config
    human_evaluation
    llm_response
    ab_test
  ]

  models_to_configure.each do |model_file|
    begin
      # Require the model file to ensure it's loaded
      require_dependency "prompt_tracker/#{model_file}"

      # Get the model class
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

      # Add acts_as_tenant
      model_class.class_eval do
        acts_as_tenant :organization
      end

      Rails.logger.info "✓ Configured acts_as_tenant for PromptTracker::#{model_file.camelize}"
    rescue LoadError => e
      Rails.logger.warn "⚠ Could not load PromptTracker::#{model_file.camelize}: #{e.message}"
    rescue StandardError => e
      Rails.logger.error "✗ Error configuring PromptTracker::#{model_file.camelize}: #{e.message}"
    end
  end
end
