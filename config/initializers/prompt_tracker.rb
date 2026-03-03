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
    unless org
      Rails.logger.info "[PromptTracker Config] No current tenant set - using static fallback configuration"
      return {}
    end

    Rails.logger.info "[PromptTracker Config] ========================================="
    Rails.logger.info "[PromptTracker Config] Building configuration for organization: #{org.name} (#{org.slug})"
    Rails.logger.info "[PromptTracker Config] ========================================="

    # Build dynamic configuration hash
    config_hash = {
      # PROVIDERS: Fetch API keys from database
      providers: build_providers_for_organization(org),

      # CONTEXTS: Fetch context defaults from database
      contexts: build_contexts_for_organization(org),

      # FEATURES: Fetch feature flags from database
      features: build_features_for_organization(org)
    }

    Rails.logger.info "[PromptTracker Config] Configuration built successfully"
    Rails.logger.info "[PromptTracker Config] Providers hash keys: #{config_hash[:providers].keys.inspect}"

    # Log what RubyLLM will receive (simulating ruby_llm_config method)
    provider_key_mapping = {
      openai: :openai_api_key,
      anthropic: :anthropic_api_key,
      google: :gemini_api_key
    }
    ruby_llm_config_preview = {}
    provider_key_mapping.each do |provider, config_key|
      api_key = config_hash[:providers].dig(provider, :api_key)
      if api_key.present?
        ruby_llm_config_preview[config_key] = mask_api_key(api_key)
      end
    end
    Rails.logger.info "[PromptTracker Config] RubyLLM config preview: #{ruby_llm_config_preview.inspect}"
    Rails.logger.info "[PromptTracker Config] ========================================="

    config_hash
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

# Mask API key for logging (show first 7 chars + "...")
def mask_api_key(key)
  return "nil" if key.nil?
  return "empty" if key.empty?
  return key if key.length < 10

  "#{key[0..6]}...#{key[-4..]}"
end

# Build providers hash with API keys from database
def build_providers_for_organization(org)
  providers = {}

  # Fetch all active API configurations for this organization
  # The query is automatically scoped by acts_as_tenant
  api_configs = ApiConfiguration.active.to_a

  # Log configuration loading
  Rails.logger.info "[PromptTracker Config] Loading providers for organization: #{org.name} (ID: #{org.id}, Slug: #{org.slug})"
  Rails.logger.info "[PromptTracker Config] Found #{api_configs.count} active API configuration(s)"

  api_configs.each do |api_config|
    provider_key = api_config.provider.to_sym
    api_key = api_config.encrypted_api_key

    providers[provider_key] = {
      api_key: api_key
    }

    # Log each provider configuration (with masked key)
    Rails.logger.info "[PromptTracker Config]   - Provider: #{provider_key}, Key Name: #{api_config.key_name}, API Key: #{mask_api_key(api_key)}"
  end

  if providers.empty?
    Rails.logger.warn "[PromptTracker Config] ⚠️  No active API configurations found for organization: #{org.name}"
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
