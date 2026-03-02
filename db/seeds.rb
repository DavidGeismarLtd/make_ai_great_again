# frozen_string_literal: true

puts "🌱 Seeding MakeAiGreatAgain database..."

# Temporarily disable tenant requirement for seeding
original_require_tenant = ActsAsTenant.configuration.require_tenant
ActsAsTenant.configuration.require_tenant = false

begin
  # ============================================================================
  # 1. CLEANUP
  # ============================================================================
  puts "\n📦 Cleaning up existing data..."

  # Clean up PromptTracker data (order matters due to foreign key constraints)
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_human_evaluations")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_evaluations")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_test_runs")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_tests")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_llm_responses")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_ab_tests")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_evaluator_configs")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_dataset_rows")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_datasets")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_prompt_versions")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_prompts")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_prompt_test_suite_runs")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_prompt_test_suites")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_spans")
  ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_traces")

  # Clean up host app data
  ApiConfiguration.delete_all
  OrganizationMembership.delete_all
  Organization.where.not(slug: 'default').delete_all
  User.delete_all

  puts "  ✓ Cleanup complete"

  # ============================================================================
  # 2. ORGANIZATIONS (Create first, before users)
  # ============================================================================
  puts "\n🏢 Creating organizations..."

  # Get or create default organization
  default_org = Organization.find_or_create_by!(slug: 'default') do |org|
    org.name = 'Default Organization'
    org.status = 'active'
  end

  acme_corp = Organization.create!(
    name: "Acme Corporation",
    slug: "acme-corp",
    status: "active"
  )

  tech_startup = Organization.create!(
    name: "Tech Startup Inc",
    slug: "tech-startup",
    status: "active"
  )

  puts "  ✓ Created #{Organization.count} organizations"

  # ============================================================================
  # 3. USERS
  # ============================================================================
  puts "\n👤 Creating users..."

  admin_user = User.new(
    email: "admin@example.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Admin",
    last_name: "User",
    role: "admin"
  )
  admin_user.skip_confirmation!
  admin_user.save!

  demo_user = User.new(
    email: "demo@example.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Demo",
    last_name: "User",
    role: "user"
  )
  demo_user.skip_confirmation!
  demo_user.save!

  puts "  ✓ Created #{User.count} users"

  # ============================================================================
  # 4. ORGANIZATION MEMBERSHIPS
  # ============================================================================
  puts "\n👥 Creating organization memberships..."

  OrganizationMembership.create!(
    user: admin_user,
    organization: acme_corp,
    role: "owner"
  )

  OrganizationMembership.create!(
    user: demo_user,
    organization: acme_corp,
    role: "member"
  )

  OrganizationMembership.create!(
    user: admin_user,
    organization: tech_startup,
    role: "owner"
  )

  puts "  ✓ Created #{OrganizationMembership.count} memberships"

  # ============================================================================
  # 5. API CONFIGURATIONS
  # ============================================================================
  puts "\n🔑 Creating API configurations..."

  ApiConfiguration.create!(
    organization: acme_corp,
    provider: "openai",
    key_name: "OpenAI Production Key",
    encrypted_api_key: ENV['OPENAI_API_KEY'] || "sk-test-key-placeholder",
    is_active: true
  )

  ApiConfiguration.create!(
    organization: acme_corp,
    provider: "anthropic",
    key_name: "Anthropic Production Key",
    encrypted_api_key: ENV['ANTHROPIC_API_KEY'] || "sk-ant-test-key-placeholder",
    is_active: true
  )

  ApiConfiguration.create!(
    organization: tech_startup,
    provider: "openai",
    key_name: "OpenAI Development Key",
    encrypted_api_key: ENV['OPENAI_API_KEY'] || "sk-test-key-placeholder",
    is_active: true
  )

  puts "  ✓ Created #{ApiConfiguration.count} API configurations"

  # ============================================================================
  # 6. PROMPTTRACKER DATA (for Acme Corp)
  # ============================================================================
  puts "\n🤖 Creating PromptTracker data for Acme Corp..."

  # Customer Support Greeting Prompt
  support_greeting = PromptTracker::Prompt.create!(
    organization_id: acme_corp.id,
    name: "customer_support_greeting",
    description: "Initial greeting for customer support interactions",
    category: "support",
    tags: ["customer-facing", "greeting", "high-priority"],
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
    tags: ["email", "automation"],
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

  # ============================================================================
  # 7. TESTS
  # ============================================================================
  puts "\n🧪 Creating tests..."

  # Test for support greeting
  test_greeting_premium = support_greeting_v2.tests.create!(
    organization_id: acme_corp.id,
    name: "Premium Customer Greeting",
    description: "Test greeting for premium customers with billing issues",
    tags: ["premium", "billing"],
    enabled: true
  )

  test_greeting_premium.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: { patterns: ["customer_name", "issue_category"], match_all: false }
  )

  test_greeting_premium.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 10, "max_length" => 500 },
    enabled: true
  )

  test_greeting_technical = support_greeting_v2.tests.create!(
    organization_id: acme_corp.id,
    name: "Technical Support Greeting",
    description: "Test greeting for technical support inquiries",
    tags: ["technical"],
    enabled: true
  )

  test_greeting_technical.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 10, "max_length" => 500 },
    enabled: true
  )

  puts "  ✓ Created #{PromptTracker::Test.count} tests with #{PromptTracker::EvaluatorConfig.count} evaluator configs"

  # ============================================================================
  # 8. DATASETS
  # ============================================================================
  puts "\n📊 Creating datasets..."

  support_dataset = PromptTracker::Dataset.create!(
    organization_id: acme_corp.id,
    testable: support_greeting_v2,
    name: "Customer Support Test Cases",
    description: "Common customer support scenarios",
    dataset_type: :single_turn  # 0=single_turn, 1=conversational
  )

  support_dataset.dataset_rows.create!([
    {
      organization_id: acme_corp.id,
      row_data: { customer_name: "John Smith", issue_category: "billing" },
      metadata: { priority: "high" },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: { customer_name: "Sarah Johnson", issue_category: "technical" },
      metadata: { priority: "medium" },
      source: "manual"
    },
    {
      organization_id: acme_corp.id,
      row_data: { customer_name: "Mike Davis", issue_category: "account" },
      metadata: { priority: "low" },
      source: "manual"
    }
  ])

  puts "  ✓ Created #{PromptTracker::Dataset.count} datasets with #{PromptTracker::DatasetRow.count} rows"

  # ============================================================================
  # 9. SUMMARY
  # ============================================================================
  puts "\n" + "=" * 80
  puts "✅ SEEDING COMPLETE!"
  puts "=" * 80
  puts ""
  puts "📊 Summary:"
  puts "  • Users: #{User.count}"
  puts "  • Organizations: #{Organization.count}"
  puts "  • Organization Memberships: #{OrganizationMembership.count}"
  puts "  • API Configurations: #{ApiConfiguration.count}"
  puts ""
  puts "🤖 PromptTracker Data:"
  puts "  • Prompts: #{PromptTracker::Prompt.count}"
  puts "  • Prompt Versions: #{PromptTracker::PromptVersion.count}"
  puts "  • Tests: #{PromptTracker::Test.count}"
  puts "  • Evaluator Configs: #{PromptTracker::EvaluatorConfig.count}"
  puts "  • Datasets: #{PromptTracker::Dataset.count}"
  puts "  • Dataset Rows: #{PromptTracker::DatasetRow.count}"
  puts ""
  puts "🔐 Login Credentials:"
  puts "  Admin: admin@example.com / password123"
  puts "  Demo:  demo@example.com / password123"
  puts ""
  puts "🏢 Organizations:"
  puts "  • Acme Corporation (slug: acme-corp)"
  puts "  • Tech Startup Inc (slug: tech-startup)"
  puts "  • Default Organization (slug: default)"
  puts ""
  puts "=" * 80
ensure
  # Restore original tenant requirement setting
  ActsAsTenant.configuration.require_tenant = original_require_tenant
end


rails console

acme = Organization.find_by(slug: 'acme-corp')
tech_startup = Organization.find_by(slug: 'tech-startup')

# Test Acme Corp tenant
  ActsAsTenant.with_tenant(acme) do
    PromptTracker::Prompt.count  # => 2
    PromptTracker::PromptVersion.count  # => 3
  end

# Test Tech Startup tenant
ActsAsTenant.with_tenant(tech_startup) do
  PromptTracker::Prompt.count  # => 0 (isolated!)
end

# Test that organization association exists
PromptTracker::Prompt.reflect_on_association(:organization).present?  # => true