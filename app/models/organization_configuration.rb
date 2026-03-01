# frozen_string_literal: true

# OrganizationConfiguration stores organization-specific PromptTracker settings
# - contexts_config: Default provider/model/temperature for each context (playground, llm_judge, etc.)
# - features_config: Feature flags (openai_assistant_sync, etc.)
class OrganizationConfiguration < ApplicationRecord
  belongs_to :organization

  # Validations
  validates :contexts_config, presence: true
  validates :features_config, presence: true
  validates :organization_id, uniqueness: true

  # Set defaults on initialization
  after_initialize :set_defaults, if: :new_record?

  # Default contexts configuration
  # Matches the structure in config/initializers/prompt_tracker.rb
  DEFAULT_CONTEXTS = {
    playground: {
      description: "Prompt version testing in the playground",
      default_provider: "openai",
      default_api: "chat_completions",
      default_model: "gpt-4o"
    },
    llm_judge: {
      description: "LLM-as-judge evaluation of responses",
      default_provider: "openai",
      default_api: "chat_completions",
      default_model: "gpt-4o"
    },
    dataset_generation: {
      description: "Generating test dataset rows via LLM",
      default_provider: "openai",
      default_api: "chat_completions",
      default_model: "gpt-4o"
    },
    prompt_generation: {
      description: "AI-assisted prompt creation and enhancement",
      default_provider: "openai",
      default_api: "chat_completions",
      default_model: "gpt-4o-mini"
    },
    test_generation: {
      description: "AI-powered test case generation for prompts",
      default_provider: "openai",
      default_api: "chat_completions",
      default_model: "gpt-4o",
      default_temperature: 0.7
    }
  }.freeze

  # Default features configuration
  DEFAULT_FEATURES = {
    openai_assistant_sync: true
  }.freeze

  private

  def set_defaults
    self.contexts_config ||= DEFAULT_CONTEXTS.deep_stringify_keys
    self.features_config ||= DEFAULT_FEATURES.deep_stringify_keys
  end
end
