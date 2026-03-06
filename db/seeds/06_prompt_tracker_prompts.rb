# frozen_string_literal: true

# ============================================================================
# PROMPTTRACKER - PROMPTS & VERSIONS
# ============================================================================
puts "\n🤖 Creating PromptTracker prompts and versions..."

acme_corp = SeedData.organizations[:acme_corp]

# Set tenant context for PromptTracker data creation
ActsAsTenant.with_tenant(acme_corp) do
  # Customer Support Greeting Prompt
  support_greeting = PromptTracker::Prompt.create!(
    organization_id: acme_corp.id,
    name: "customer_support_greeting",
    description: "Initial greeting for customer support interactions",
    category: "support",
    tags: [ "customer-facing", "greeting", "high-priority" ],
    created_by: "admin@example.com"
  )

  # Version 1 - Deprecated
  support_greeting_v1 = support_greeting.prompt_versions.create!(
    organization_id: acme_corp.id,
    user_prompt: "Hello {{customer_name}}! Thank you for contacting support. How can I help you with {{issue_category}} today?",
    status: "deprecated",
    variables_schema: [
      { "name" => "customer_name", "type" => "string", "required" => true },
      { "name" => "issue_category", "type" => "string", "required" => false }
    ],
    model_config: {
      "provider" => "openai",
      "api" => "chat_completions",
      "model" => "gpt-4o-mini",
      "temperature" => 0.7,
      "max_tokens" => 150
    },
    notes: "Original version - too formal",
    created_by: "admin@example.com"
  )

  # Version 2 - Active
  support_greeting_v2 = support_greeting.prompt_versions.create!(
    organization_id: acme_corp.id,
    user_prompt: "Hi {{customer_name}}! Thanks for contacting us. I'm here to help with your {{issue_category}} question. What's going on?",
    status: "active",
    variables_schema: [
      { "name" => "customer_name", "type" => "string", "required" => true },
      { "name" => "issue_category", "type" => "string", "required" => true }
    ],
    model_config: {
      "provider" => "openai",
      "api" => "chat_completions",
      "model" => "gpt-4o",
      "temperature" => 0.7,
      "max_tokens" => 120
    },
    notes: "Best performing version - friendly but professional",
    created_by: "admin@example.com"
  )

  # Email Generation Prompt
  email_prompt = PromptTracker::Prompt.create!(
    organization_id: acme_corp.id,
    name: "email_generation",
    description: "Generate professional emails based on context",
    category: "communication",
    tags: [ "email", "automation" ],
    created_by: "admin@example.com"
  )

  email_prompt_v1 = email_prompt.prompt_versions.create!(
    organization_id: acme_corp.id,
    system_prompt: "You are a professional email writer. Write clear, concise, and professional emails.",
    user_prompt: "Write an email about: {{topic}}\nTone: {{tone}}\nRecipient: {{recipient}}",
    status: "active",
    variables_schema: [
      { "name" => "topic", "type" => "string", "required" => true },
      { "name" => "tone", "type" => "string", "required" => true },
      { "name" => "recipient", "type" => "string", "required" => true }
    ],
    model_config: {
      "provider" => "anthropic",
      "api" => "messages",
      "model" => "claude-sonnet-4-20250514",
      "temperature" => 0.6,
      "max_tokens" => 500
    },
    notes: "Using Claude for better writing quality",
    created_by: "admin@example.com"
  )

  puts "  ✓ Created #{PromptTracker::Prompt.count} prompts with #{PromptTracker::PromptVersion.count} versions"

  # Store for use in other seed files
  SeedData.prompt_versions = {
    support_greeting_v1: support_greeting_v1,
    support_greeting_v2: support_greeting_v2,
    email_prompt_v1: email_prompt_v1
  }
end

