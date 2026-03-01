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

    # Map provider names to ENV variable names expected by RubyLLM
    provider_env_map = {
      "openai" => "OPENAI_API_KEY",
      "anthropic" => "ANTHROPIC_API_KEY",
      "google" => "GOOGLE_API_KEY",
      "azure_openai" => "AZURE_OPENAI_API_KEY"
    }

    # Fetch all active API configurations for the current organization
    # This query is automatically scoped by acts_as_tenant
    ApiConfiguration.active.each do |api_config|
      env_var_name = provider_env_map[api_config.provider]
      next unless env_var_name

      # Set the ENV variable with the decrypted API key
      # Rails automatically decrypts the encrypted_api_key attribute
      ENV[env_var_name] = api_config.encrypted_api_key if api_config.encrypted_api_key.present?
    end
  end
end
