# frozen_string_literal: true

# ============================================================================
# PROMPTTRACKER - AGENTS & VERSIONS
# ============================================================================
puts "\n🤖 Creating PromptTracker agents and versions..."

acme_corp = SeedData.organizations[:acme_corp]

# Set tenant context for PromptTracker data creation
ActsAsTenant.with_tenant(acme_corp) do
  # ============================================================================
  # 1. Customer Support Greeting Agent
  # ============================================================================
  puts "  Creating customer support agents..."

  support_greeting = PromptTracker::Agent.create!(
    organization_id: acme_corp.id,
    name: "customer_support_greeting",
    description: "Initial greeting for customer support interactions",
    category: "support",
    tags: [ "customer-facing", "greeting", "high-priority" ],
    created_by: "support-team@example.com"
  )

  # Version 1 - Original (deprecated)
  support_greeting_v1 = support_greeting.agent_versions.create!(
    organization_id: acme_corp.id,
    system_prompt: "You are a friendly customer support agent. Greet the customer and help them with their issue.",
    user_prompt: "Hello {{customer_name}}! Thank you for contacting support. How can I help you with {{issue_category}} today?",
    version_number: 1,
    status: "deprecated",
    variables_schema: [
      { "name" => "customer_name", "type" => "string", "required" => true },
      { "name" => "issue_category", "type" => "string", "required" => false }
    ],
    model_config: {
      "provider" => "openai",
      "api" => "chat_completions",
      "model" => "gpt-3.5-turbo",
      "temperature" => 0.7,
      "max_tokens" => 150
    },
    notes: "Original version - too formal",
    created_by: "john@example.com"
  )

  # Version 2 - More casual (deprecated)
  support_greeting_v2 = support_greeting.agent_versions.create!(
    organization_id: acme_corp.id,
    system_prompt: "You are a casual, friendly customer support agent. Use a warm, approachable tone.",
    user_prompt: "Hi {{customer_name}}! 👋 Thanks for reaching out. What can I help you with today?",
    version_number: 2,
    status: "deprecated",
    variables_schema: [
      { "name" => "customer_name", "type" => "string", "required" => true }
    ],
    model_config: {
      "provider" => "openai",
      "api" => "chat_completions",
      "model" => "gpt-4o-mini",
      "temperature" => 0.8,
      "max_tokens" => 100
    },
    notes: "Tested in web UI - more casual tone",
    created_by: "sarah@example.com"
  )

  # Version 3 - Current active version
  support_greeting_v3 = support_greeting.agent_versions.create!(
    organization_id: acme_corp.id,
    system_prompt: "You are a professional yet friendly customer support agent. Be helpful and empathetic while staying efficient.",
    user_prompt: "Hi {{customer_name}}! Thanks for contacting us. I'm here to help with your {{issue_category}} question. What's going on?",
    version_number: 3,
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
    created_by: "john@example.com"
  )

  # Version 4 - Draft: Testing casual tone
  support_greeting_v4 = support_greeting.agent_versions.create!(
    organization_id: acme_corp.id,
    system_prompt: "You are a very casual customer support agent. Use informal language and be super approachable.",
    user_prompt: "Hey {{customer_name}}! What's up with {{issue_category}}?",
    version_number: 4,
    status: "draft",
    variables_schema: [
      { "name" => "customer_name", "type" => "string", "required" => true },
      { "name" => "issue_category", "type" => "string", "required" => true }
    ],
    model_config: {
      "provider" => "openai",
      "api" => "chat_completions",
      "model" => "gpt-4o-mini",
      "temperature" => 0.9,
      "max_tokens" => 80
    },
    notes: "Testing very casual tone for A/B test",
    created_by: "sarah@example.com"
  )

  # Version 5 - Draft: Using Anthropic Claude
  support_greeting_v5 = support_greeting.agent_versions.create!(
    organization_id: acme_corp.id,
    system_prompt: "You are an empathetic customer support agent. Listen carefully, acknowledge the customer's feelings, and provide thoughtful assistance.",
    user_prompt: "Hi {{customer_name}}, I understand you're having an issue with {{issue_category}}. I'm here to help you resolve this. Can you tell me more about what's happening?",
    version_number: 5,
    status: "draft",
    variables_schema: [
      { "name" => "customer_name", "type" => "string", "required" => true },
      { "name" => "issue_category", "type" => "string", "required" => true }
    ],
    model_config: {
      "provider" => "anthropic",
      "api" => "messages",
      "model" => "claude-sonnet-4-20250514",
      "temperature" => 0.6,
      "max_tokens" => 150
    },
    notes: "Testing Anthropic Claude - more empathetic approach",
    created_by: "alice@example.com"
  )

  puts "  ✓ Created customer support agents (1 agent, 5 versions)"

  # ============================================================================
  # 2. Email Summary Generator Agent
  # ============================================================================
  puts "  Creating email generation agents..."

  email_summary = PromptTracker::Agent.create!(
    organization_id: acme_corp.id,
    name: "email_summary_generator",
    description: "Generates concise summaries of long email threads",
    category: "email",
    tags: [ "productivity", "summarization" ],
    created_by: "product-team@example.com"
  )

  # Version 1 - Paragraph format (active)
  email_summary_v1 = email_summary.agent_versions.create!(
    organization_id: acme_corp.id,
    system_prompt: "You are an email summarization assistant. Your role is to read email threads and provide concise, accurate summaries.",
    user_prompt: "Summarize the following email thread in 2-3 sentences:\n\n{{email_thread}}",
    version_number: 1,
    status: "active",
    variables_schema: [
      { "name" => "email_thread", "type" => "string", "required" => true }
    ],
    model_config: {
      "provider" => "openai",
      "api" => "chat_completions",
      "model" => "gpt-4o",
      "temperature" => 0.5,
      "max_tokens" => 300
    },
    notes: "Paragraph format - concise and readable",
    created_by: "alice@example.com"
  )

  # Version 2 - Bullet points format (draft)
  email_summary_v2 = email_summary.agent_versions.create!(
    organization_id: acme_corp.id,
    system_prompt: "You are an email summarization assistant. Provide summaries in bullet point format for easy scanning.",
    user_prompt: "Summarize the following email thread as bullet points:\n\n{{email_thread}}",
    version_number: 2,
    status: "draft",
    variables_schema: [
      { "name" => "email_thread", "type" => "string", "required" => true }
    ],
    model_config: {
      "provider" => "openai",
      "api" => "chat_completions",
      "model" => "gpt-4o",
      "temperature" => 0.5,
      "max_tokens" => 300
    },
    notes: "Testing bullet point format for better scannability",
    created_by: "bob@example.com"
  )

  puts "  ✓ Created email summary agents (1 agent, 2 versions)"

  # ============================================================================
  # 3. Code Review Assistant Agent
  # ============================================================================
  puts "  Creating code review agents..."

  code_review = PromptTracker::Agent.create!(
    organization_id: acme_corp.id,
    name: "code_review_assistant",
    description: "Reviews code for quality, bugs, and best practices",
    category: "development",
    tags: [ "code-review", "quality", "technical" ],
    created_by: "engineering-team@example.com"
  )

  # Version 1 - Active
  code_review_v1 = code_review.agent_versions.create!(
    organization_id: acme_corp.id,
    system_prompt: <<~SYSTEM.strip,
      You are a code review assistant. Your role is to:
      1. Identify potential bugs and edge cases
      2. Suggest improvements for code quality and readability
      3. Check for best practices and design patterns
      4. Provide constructive, actionable feedback

      Focus on being helpful and educational, not critical.
    SYSTEM
    user_prompt: "Review the following {{language}} code:\n\n```{{language}}\n{{code}}\n```",
    version_number: 1,
    status: "active",
    variables_schema: [
      { "name" => "language", "type" => "string", "required" => true },
      { "name" => "code", "type" => "string", "required" => true }
    ],
    model_config: {
      "provider" => "openai",
      "api" => "chat_completions",
      "model" => "gpt-4o",
      "temperature" => 0.3,
      "max_tokens" => 1000
    },
    notes: "Comprehensive code review with focus on quality and best practices",
    created_by: "tech-lead@example.com"
  )

  puts "  ✓ Created code review agents (1 agent, 1 version)"

  # Store for use in other seed files
  SeedData.prompt_versions = {
    support_greeting_v1: support_greeting_v1,
    support_greeting_v2: support_greeting_v2,
    support_greeting_v3: support_greeting_v3,
    support_greeting_v4: support_greeting_v4,
    support_greeting_v5: support_greeting_v5,
    email_summary_v1: email_summary_v1,
    email_summary_v2: email_summary_v2,
    code_review_v1: code_review_v1
  }

  puts "\n  ✅ Total: #{PromptTracker::Agent.count} agents with #{PromptTracker::AgentVersion.count} versions"
end
