# frozen_string_literal: true

# OrganizationConfiguration stores organization-specific PromptTracker settings
# - contexts_config: Default provider/model/temperature for each context (playground, llm_judge, etc.)
# - features_config: Feature flags (openai_assistant_sync, monitoring, functions, etc.)
# - function_providers_config: Function execution provider settings (AWS Lambda, etc.)
# - assistant_chatbot_config: Built-in assistant chatbot settings (enabled, model, etc.)
class OrganizationConfiguration < ApplicationRecord
  belongs_to :organization

  # Validations
  validates :contexts_config, presence: true
  validates :features_config, presence: true
  validates :organization_id, uniqueness: true

  # Set defaults before validation
  before_validation :set_defaults, on: :create

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
    openai_assistant_sync: true,
    monitoring: false,
    functions: false
  }.freeze

  # Default function providers configuration
  DEFAULT_FUNCTION_PROVIDERS = {
    aws_lambda: {
      region: "",
      access_key_id: "",
      secret_access_key: "",
      execution_role_arn: "",
      function_prefix: "prompt-tracker"
    }
  }.freeze

  # Default assistant chatbot configuration
  # Structure must match what the PromptTracker gem expects:
  # { enabled: bool, model: { provider:, api:, model: } }
  DEFAULT_ASSISTANT_CHATBOT = {
    enabled: false,
    model: {
      provider: "openai",
      api: "chat_completions",
      model: "gpt-4o"
    }
  }.freeze

  private

  def set_defaults
    self.contexts_config = DEFAULT_CONTEXTS.deep_stringify_keys if contexts_config.blank?
    self.features_config = DEFAULT_FEATURES.deep_stringify_keys if features_config.blank?
    self.function_providers_config = DEFAULT_FUNCTION_PROVIDERS.deep_stringify_keys if function_providers_config.blank?
    self.assistant_chatbot_config = DEFAULT_ASSISTANT_CHATBOT.deep_stringify_keys if assistant_chatbot_config.blank?
  end
end
