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

# Global MCP server definitions (transport, command, args).
# Defined outside PromptTracker.configure so that build_mcp_servers_for_organization
# can reference them without triggering a circular call through the configuration_provider.
GLOBAL_MCP_SERVER_DEFINITIONS = {
  filesystem: {
    transport: "stdio",
    command: "npx",
    args: [ "-y", "@modelcontextprotocol/server-filesystem", "/tmp", Rails.root.to_s ],
    env: {}
  },
  slack: {
    transport: "stdio",
    command: "npx",
    args: [ "-y", "@modelcontextprotocol/server-slack" ],
    env: {
      "SLACK_BOT_TOKEN" => ENV["SLACK_BOT_TOKEN"],
      "SLACK_TEAM_ID" => ENV["SLACK_TEAM_ID"]
    }
  }
}.freeze

PromptTracker.configure do |config|
  # ===========================================================================
  # 1. STATIC SETTINGS (applied to all requests)
  # ===========================================================================
  config.basic_auth_username = nil
  config.basic_auth_password = nil

  # ===========================================================================
  # 2. URL OPTIONS PROVIDER (for multi-tenant URL generation)
  # ===========================================================================
  # This lambda provides URL parameters needed for organization-scoped routes.
  # The engine is mounted under /orgs/:org_slug/app, so we need to provide
  # the org_slug parameter for all URL generation.
  config.url_options_provider = -> {
    { org_slug: ActsAsTenant.current_tenant&.slug }
  }

  # ===========================================================================
  # 3. DYNAMIC CONFIGURATION PROVIDER
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
      Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] No current tenant set - using static fallback configuration"
      return {}
    end

    Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] ========================================="
    Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] Building configuration for organization: #{org.name} (#{org.slug})"
    Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] ========================================="

    # Build dynamic configuration hash
    config_hash = {
      # PROVIDERS: Fetch API keys from database
      providers: build_providers_for_organization(org),

      # CONTEXTS: Fetch context defaults from database
      contexts: build_contexts_for_organization(org),

      # FEATURES: Fetch feature flags from database
      features: build_features_for_organization(org),

      # FUNCTION PROVIDERS: Fetch function provider settings from database
      function_providers: build_function_providers_for_organization(org),

      # ASSISTANT CHATBOT: Fetch assistant chatbot settings from database
      assistant_chatbot: build_assistant_chatbot_for_organization(org),

      # MCP SERVERS: Fetch MCP server settings from database
      mcp_servers: build_mcp_servers_for_organization(org)
    }

    Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] Configuration built successfully"
    Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] Providers hash keys: #{config_hash[:providers].keys.inspect}"

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
    Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] RubyLLM config preview: #{ruby_llm_config_preview.inspect}"
    Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] ========================================="

    config_hash
  }

  # ===========================================================================
  # 3. STATIC FALLBACKS (no-tenant context only)
  # ===========================================================================
  # These are ONLY used when no tenant is set (e.g., Rails console, background
  # jobs without tenant context). In that case configuration_provider returns {}
  # and these kick in. They are intentionally empty/safe — all real config lives
  # in the database per organization.
  config.contexts = {}
  config.features = {}
  config.providers = {}
  config.function_providers = {}
  config.mcp_servers = {}
  config.assistant_chatbot = { enabled: false }
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
  Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] Loading providers for organization: #{org.name} (ID: #{org.id}, Slug: #{org.slug})"
  Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config] Found #{api_configs.count} active API configuration(s)"

  api_configs.each do |api_config|
    provider_key = api_config.provider.to_sym
    api_key = api_config.encrypted_api_key

    providers[provider_key] = {
      api_key: api_key
    }

    # Log each provider configuration (with masked key)
    Rails.logger.info "[MakeAIGreatAgain] [PromptTracker Config]   - Provider: #{provider_key}, Key Name: #{api_config.key_name}, API Key: #{mask_api_key(api_key)}"
  end

  if providers.empty?
    Rails.logger.warn "[MakeAIGreatAgain] [PromptTracker Config] ⚠️  No active API configurations found for organization: #{org.name}"
  end

  providers
end

# Build contexts hash from database
def build_contexts_for_organization(org)
  org_config = org.organization_configuration
  return {} unless org_config

  # Convert string keys to symbols and ensure numeric values are properly typed
  contexts = org_config.contexts_config.deep_symbolize_keys

  # Type coercion: Convert string numeric values to proper types
  # This is necessary because JSONB stores numbers as strings when saved from forms
  contexts.each do |context_key, context_config|
    next unless context_config.is_a?(Hash)

    context_config.each do |key, value|
      # Convert temperature, max_tokens, top_p, etc. from strings to numbers
      if key.to_s.include?("temperature") || key.to_s.include?("top_p")
        contexts[context_key][key] = value.to_f if value.is_a?(String)
      elsif key.to_s.include?("max_tokens") || key.to_s.include?("max_")
        contexts[context_key][key] = value.to_i if value.is_a?(String)
      end
    end
  end

  contexts
end

# Build features hash from database
def build_features_for_organization(org)
  org_config = org.organization_configuration
  return {} unless org_config

  # Convert string keys to symbols for PromptTracker
  org_config.features_config.deep_symbolize_keys
end

# Build function providers hash from database
def build_function_providers_for_organization(org)
  org_config = org.organization_configuration
  return {} unless org_config

  org_config.function_providers_config.deep_symbolize_keys
end

# Build assistant chatbot hash from database
def build_assistant_chatbot_for_organization(org)
  org_config = org.organization_configuration
  return {} unless org_config

  config = org_config.assistant_chatbot_config.deep_symbolize_keys
  # Ensure :enabled is a proper boolean (JSONB may store "true"/"false" strings)
  config[:enabled] = config[:enabled] == true || config[:enabled] == "true"
  config
end

# Build MCP servers hash from database
# Merges org-level enabled flags and credentials with the global server definitions.
# Only returns servers that the org has enabled.
def build_mcp_servers_for_organization(org)
  org_config = org.organization_configuration
  return {} unless org_config

  mcp_org_config = org_config.mcp_servers_config.deep_symbolize_keys
  global_servers = GLOBAL_MCP_SERVER_DEFINITIONS

  enabled_servers = {}

  mcp_org_config.each do |server_name, org_settings|
    next unless org_settings[:enabled] == true || org_settings[:enabled] == "true"
    next unless global_servers.key?(server_name)

    server_def = global_servers[server_name].deep_dup

    # Override env vars with org-specific credentials
    if server_name == :slack
      server_def[:env] ||= {}
      server_def[:env]["SLACK_BOT_TOKEN"] = org_settings[:slack_bot_token] if org_settings[:slack_bot_token].present?
      server_def[:env]["SLACK_TEAM_ID"] = org_settings[:slack_team_id] if org_settings[:slack_team_id].present?
    end

    enabled_servers[server_name] = server_def
  end

  enabled_servers
end
