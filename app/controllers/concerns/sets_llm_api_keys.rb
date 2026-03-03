# frozen_string_literal: true

# Concern to set LLM API keys from the current organization's API configurations.
#
# This concern is included in ApplicationController to ensure that ENV variables
# for LLM providers (OpenAI, Anthropic, Google, etc.) are set before each request
# based on the current organization's API configurations.
#
# How it works:
# 1. The before_action :set_llm_api_keys runs after set_current_tenant
# 2. It fetches all active API configurations for the current organization
# 3. It sets the corresponding ENV variables (OPENAI_API_KEY, ANTHROPIC_API_KEY, etc.)
# 4. RubyLLM (used by PromptTracker) automatically picks up these ENV variables
#
# This ensures that each organization uses their own API keys for LLM calls.
#
# Note: ENV variables are thread-safe in Ruby, so this works correctly in
# multi-threaded environments like Puma.
module SetsLlmApiKeys
  extend ActiveSupport::Concern

  included do
    # Run after set_current_tenant to ensure we have the current organization
    # Only run if we have a tenant set (avoid NoTenantSet errors on non-org pages)
    before_action :set_llm_api_keys, if: :tenant_set?
  end

  private

  # Check if a tenant is set without raising an error
  def tenant_set?
    user_signed_in? && ActsAsTenant.current_tenant.present?
  rescue ActsAsTenant::Errors::NoTenantSet
    false
  end

  # Set ENV variables for LLM providers based on current organization's API configurations
  def set_llm_api_keys
    return unless ActsAsTenant.current_tenant

    org = ActsAsTenant.current_tenant

    Rails.logger.info "[LLM API Keys] ========================================="
    Rails.logger.info "[LLM API Keys] Setting ENV variables for organization: #{org.name} (ID: #{org.id}, Slug: #{org.slug})"
    Rails.logger.info "[LLM API Keys] Request: #{request.method} #{request.path}" if respond_to?(:request)
    Rails.logger.info "[LLM API Keys] ========================================="

    # Map provider names to ENV variable names expected by RubyLLM
    provider_env_map = {
      "openai" => "OPENAI_API_KEY",
      "anthropic" => "ANTHROPIC_API_KEY",
      "google" => "GOOGLE_API_KEY",
      "azure_openai" => "AZURE_OPENAI_API_KEY"
    }

    # Fetch all active API configurations for the current organization
    # This query is automatically scoped by acts_as_tenant
    api_configs = ApiConfiguration.active.to_a

    Rails.logger.info "[LLM API Keys] Found #{api_configs.count} active API configuration(s)"

    api_configs.each do |api_config|
      env_var_name = provider_env_map[api_config.provider]
      next unless env_var_name

      # Set the ENV variable with the decrypted API key
      # Rails automatically decrypts the encrypted_api_key attribute
      api_key = api_config.encrypted_api_key

      if api_key.present?
        ENV[env_var_name] = api_key
        masked_key = mask_api_key_for_logging(api_key)
        Rails.logger.info "[LLM API Keys]   ✓ Set #{env_var_name} = #{masked_key} (from: #{api_config.key_name})"
      else
        Rails.logger.warn "[LLM API Keys]   ✗ Skipped #{env_var_name} - API key is empty (config: #{api_config.key_name})"
      end
    end

    if api_configs.empty?
      Rails.logger.warn "[LLM API Keys] ⚠️  No active API configurations found - ENV variables not set"
    end

    Rails.logger.info "[LLM API Keys] ========================================="
  end

  # Mask API key for logging (show first 7 chars + last 4 chars)
  def mask_api_key_for_logging(key)
    return "nil" if key.nil?
    return "empty" if key.empty?
    return key if key.length < 10

    "#{key[0..6]}...#{key[-4..]}"
  end
end
