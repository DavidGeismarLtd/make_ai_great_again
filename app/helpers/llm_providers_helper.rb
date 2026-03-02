# frozen_string_literal: true

# Helper for LLM provider information (models, APIs, etc.)
# This helper provides constants and methods for working with different LLM providers
# and their available models and APIs.
module LlmProvidersHelper
  # Available APIs per provider
  # OpenAI supports both chat_completions and assistants
  # All other providers only support chat_completions
  PROVIDER_APIS = {
    "openai" => [
      { value: "chat_completions", label: "Chat Completions" },
      { value: "assistants", label: "Assistants API" }
    ],
    "anthropic" => [
      { value: "chat_completions", label: "Chat Completions" }
    ],
    "google" => [
      { value: "chat_completions", label: "Chat Completions" }
    ],
    "azure_openai" => [
      { value: "chat_completions", label: "Chat Completions" },
      { value: "assistants", label: "Assistants API" }
    ]
  }.freeze

  # Available models per provider
  # Based on RubyLLM and current provider offerings
  PROVIDER_MODELS = {
    "openai" => [
      { value: "gpt-4o", label: "GPT-4o (Latest)" },
      { value: "gpt-4o-mini", label: "GPT-4o Mini" },
      { value: "gpt-4-turbo", label: "GPT-4 Turbo" },
      { value: "gpt-4", label: "GPT-4" },
      { value: "gpt-3.5-turbo", label: "GPT-3.5 Turbo" }
    ],
    "anthropic" => [
      { value: "claude-3-5-sonnet-20241022", label: "Claude 3.5 Sonnet (Latest)" },
      { value: "claude-3-opus-20240229", label: "Claude 3 Opus" },
      { value: "claude-3-sonnet-20240229", label: "Claude 3 Sonnet" },
      { value: "claude-3-haiku-20240307", label: "Claude 3 Haiku" }
    ],
    "google" => [
      { value: "gemini-1.5-pro", label: "Gemini 1.5 Pro" },
      { value: "gemini-1.5-flash", label: "Gemini 1.5 Flash" },
      { value: "gemini-pro", label: "Gemini Pro" }
    ],
    "azure_openai" => [
      { value: "gpt-4o", label: "GPT-4o (Latest)" },
      { value: "gpt-4o-mini", label: "GPT-4o Mini" },
      { value: "gpt-4-turbo", label: "GPT-4 Turbo" },
      { value: "gpt-4", label: "GPT-4" },
      { value: "gpt-3.5-turbo", label: "GPT-3.5 Turbo" }
    ]
  }.freeze

  # Get available APIs for a provider
  def apis_for_provider(provider)
    PROVIDER_APIS[provider.to_s] || []
  end

  # Get available models for a provider
  def models_for_provider(provider)
    PROVIDER_MODELS[provider.to_s] || []
  end

  # Get all provider APIs as JSON for JavaScript
  def provider_apis_json
    PROVIDER_APIS.to_json
  end

  # Get all provider models as JSON for JavaScript
  def provider_models_json
    PROVIDER_MODELS.to_json
  end
end

