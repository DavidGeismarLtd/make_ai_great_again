# frozen_string_literal: true

# PromptTracker Configuration
#
# This initializer configures PromptTracker with dynamic, organization-specific settings.
# Using the configuration_provider pattern, we fetch API keys, contexts, and features
# from the database based on the current organization (tenant).
#
# How it works:
# 1. ActsAsTenant sets the current organization based on the URL (:org_slug)
# 2. The configuration_provider lambda is called at runtime for each request
# 3. It fetches organization-specific settings from the database
# 4. PromptTracker uses these dynamic settings, falling back to static defaults
#
# This ensures complete data isolation and allows each organization to have
# their own API keys, context defaults, and feature flags.

PromptTracker.configure do |config|
  # ===========================================================================
  # 1. STATIC SETTINGS (applied to all requests)
  # ===========================================================================
  config.basic_auth_username = nil
  config.basic_auth_password = nil

  # ===========================================================================
  # 2. DYNAMIC CONFIGURATION PROVIDER
  # ===========================================================================
  # This lambda is called at runtime to get organization-specific configuration.
  # It returns a hash with providers, contexts, and features for the current org.
  #
  # The configuration_provider is called whenever PromptTracker needs config values.
  # It has access to ActsAsTenant.current_tenant, which is set by the
  # set_current_tenant before_action in ApplicationController.
  config.configuration_provider = lambda {
    # Get current organization from ActsAsTenant
    org = ActsAsTenant.current_tenant

    # Return empty hash to use static fallbacks when no org context
    # (e.g., in console, background jobs without tenant context)
    return {} unless org

    # Build dynamic configuration hash
    {
      # PROVIDERS: Fetch API keys from database
      providers: build_providers_for_organization(org),

      # CONTEXTS: Fetch context defaults from database
      contexts: build_contexts_for_organization(org),

      # FEATURES: Fetch feature flags from database
      features: build_features_for_organization(org)
    }
  }

  # ===========================================================================
  # 3. STATIC FALLBACK: CONTEXTS
  # ===========================================================================
  # Usage scenarios with their default selections.
  # These are used when configuration_provider returns nil/empty or doesn't
  # include a contexts key (e.g., console, background jobs without tenant).
  #
  # Organizations can customize these via Organization Settings UI.
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
  # 4. STATIC FALLBACK: FEATURE FLAGS
  # ===========================================================================
  # Feature flags that control optional functionality.
  # These are used when configuration_provider returns nil/empty or doesn't
  # include a features key (e.g., console, background jobs without tenant).
  #
  # Organizations can customize these via Organization Settings UI.
  config.features = {
    openai_assistant_sync: true  # Show "Sync OpenAI Assistants" button in Testing Dashboard
  }

  # ===========================================================================
  # 5. STATIC FALLBACK: PROVIDERS
  # ===========================================================================
  # Fallback API keys from environment variables.
  # These are used when configuration_provider returns nil/empty or doesn't
  # include a providers key.
  #
  # In production, these should be empty since we use database-stored keys.
  config.providers = {
    openai: { api_key: ENV["OPENAI_API_KEY"] },
    anthropic: { api_key: ENV["ANTHROPIC_API_KEY"] },
    google: { api_key: ENV["GOOGLE_API_KEY"] }
  }
end

# ===========================================================================
# HELPER METHODS FOR CONFIGURATION PROVIDER
# ===========================================================================

# Build providers hash with API keys from database
def build_providers_for_organization(org)
  providers = {}

  # Fetch all active API configurations for this organization
  # The query is automatically scoped by acts_as_tenant
  ApiConfiguration.active.each do |api_config|
    provider_key = api_config.provider.to_sym

    providers[provider_key] = {
      api_key: api_config.encrypted_api_key
    }
  end

  providers
end

# Build contexts hash from database
def build_contexts_for_organization(org)
  org_config = org.organization_configuration
  return {} unless org_config

  # Convert string keys to symbols for PromptTracker
  org_config.contexts_config.deep_symbolize_keys
end

# Build features hash from database
def build_features_for_organization(org)
  org_config = org.organization_configuration
  return {} unless org_config

  # Convert string keys to symbols for PromptTracker
  org_config.features_config.deep_symbolize_keys
end
