# frozen_string_literal: true

# PromptTracker Configuration
#
# This initializer configures PromptTracker with dynamic, organization-specific API keys.
# Instead of using static ENV variables, API keys are fetched from the database
# based on the current organization (tenant).
#
# How it works:
# 1. ActsAsTenant sets the current organization based on the URL (:org_slug)
# 2. When PromptTracker needs an API key, it calls config.api_key_for(provider)
# 3. We override this method to fetch the key from the ApiConfiguration model
# 4. The key is automatically scoped to the current organization via acts_as_tenant
#
# This ensures complete data isolation and allows each organization to use
# their own API keys for LLM providers.

PromptTracker.configure do |config|
  # ===========================================================================
  # 1. CORE SETTINGS
  # ===========================================================================
  config.basic_auth_username = nil
  config.basic_auth_password = nil

  # ===========================================================================
  # 2. DYNAMIC API KEY RESOLUTION
  # ===========================================================================
  # Override the api_key_for method to fetch keys from the database
  # instead of using static configuration.
  #
  # This method is called by PromptTracker whenever it needs an API key
  # for a specific provider (e.g., :openai, :anthropic, :google).
  #
  # The method:
  # 1. Gets the current organization from ActsAsTenant
  # 2. Queries the api_configurations table for an active key
  # 3. Returns the decrypted API key or nil if not found
  #
  # Note: This relies on ActsAsTenant.current_tenant being set, which happens
  # automatically in controllers via the set_current_tenant before_action.
  config.define_singleton_method(:api_key_for) do |provider|
    # Get current organization from ActsAsTenant
    org = ActsAsTenant.current_tenant

    # Return nil if no tenant is set (e.g., in console or background jobs)
    return nil unless org

    # Fetch the active API configuration for this provider
    # The query is automatically scoped to the current organization
    # via acts_as_tenant's default_scope
    api_config = ApiConfiguration
      .active
      .find_by(provider: provider.to_s)

    # Return the decrypted API key (Rails handles decryption automatically)
    api_config&.encrypted_api_key
  end

  # Override provider_configured? to check database instead of static config
  config.define_singleton_method(:provider_configured?) do |provider|
    org = ActsAsTenant.current_tenant
    return false unless org

    ApiConfiguration
      .active
      .exists?(provider: provider.to_s)
  end

  # Override enabled_providers to return providers from database
  config.define_singleton_method(:enabled_providers) do
    org = ActsAsTenant.current_tenant
    return [] unless org

    ApiConfiguration
      .active
      .pluck(:provider)
      .map(&:to_sym)
      .uniq
  end

  # ===========================================================================
  # 3. CONTEXTS
  # ===========================================================================
  # Usage scenarios with their default selections.
  # Each context specifies which provider/api/model to use by default.
  config.contexts = {
    playground: {
      description: "Prompt version testing in the playground",
      default_provider: :openai,
      default_api: :chat_completions,
      default_model: "gpt-4o"
    },
    llm_judge: {
      description: "LLM-as-judge evaluation of responses",
      default_provider: :openai,
      default_api: :chat_completions,
      default_model: "gpt-4o"
    },
    dataset_generation: {
      description: "Generating test dataset rows via LLM",
      default_provider: :openai,
      default_api: :chat_completions,
      default_model: "gpt-4o"
    },
    prompt_generation: {
      description: "AI-assisted prompt creation and enhancement",
      default_provider: :openai,
      default_api: :chat_completions,
      default_model: "gpt-4o-mini"
    },
    test_generation: {
      description: "AI-powered test case generation for prompts",
      default_provider: :openai,
      default_api: :chat_completions,
      default_model: "gpt-4o",
      default_temperature: 0.7
    }
  }

  # ===========================================================================
  # 4. FEATURE FLAGS
  # ===========================================================================
  config.features = {
    openai_assistant_sync: true  # Show "Sync OpenAI Assistants" button in Testing Dashboard
  }
end

# ===========================================================================
# 5. ENVIRONMENT VARIABLE SETUP FOR RUBYLLM
# ===========================================================================
# RubyLLM (used by PromptTracker) expects API keys to be available as
# environment variables. We need to set these dynamically based on the
# current organization's API configurations.
#
# IMPORTANT: We need to patch the PromptTracker LLM services to set ENV
# variables before each call. This is done in a separate initializer that
# runs after PromptTracker is loaded.
#
# For reference, RubyLLM expects these ENV variables:
# - OPENAI_API_KEY
# - ANTHROPIC_API_KEY
# - GOOGLE_API_KEY (or GEMINI_API_KEY)
# - AZURE_OPENAI_API_KEY
#
# These are set dynamically per-request based on the current organization.

# Helper method to set ENV variables for RubyLLM based on current organization
def self.set_api_keys_from_current_org!
  org = ActsAsTenant.current_tenant
  return unless org

  # Map provider names to ENV variable names
  provider_env_map = {
    'openai' => 'OPENAI_API_KEY',
    'anthropic' => 'ANTHROPIC_API_KEY',
    'google' => 'GOOGLE_API_KEY',
    'azure_openai' => 'AZURE_OPENAI_API_KEY'
  }

  # Fetch all active API configurations for the current organization
  ApiConfiguration.active.each do |api_config|
    env_var_name = provider_env_map[api_config.provider]
    next unless env_var_name

    # Set the ENV variable with the decrypted API key
    ENV[env_var_name] = api_config.encrypted_api_key if api_config.encrypted_api_key.present?
  end
end
