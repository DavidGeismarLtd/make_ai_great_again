# frozen_string_literal: true

# ============================================================================
# PROMPTTRACKER - TESTS & EVALUATORS
# ============================================================================
puts "\n🧪 Creating PromptTracker tests..."

acme_corp = SeedData.organizations[:acme_corp]
support_greeting_v2 = SeedData.prompt_versions[:support_greeting_v2]

ActsAsTenant.with_tenant(acme_corp) do
  # Test for support greeting - Premium customers
  test_greeting_premium = support_greeting_v2.tests.create!(
    organization_id: acme_corp.id,
    name: "Premium Customer Greeting",
    description: "Test greeting for premium customers with billing issues",
    tags: [ "premium", "billing" ],
    enabled: true
  )

  test_greeting_premium.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: { patterns: [ "customer_name", "issue_category" ], match_all: false }
  )

  test_greeting_premium.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 10, "max_length" => 500 },
    enabled: true
  )

  # Test for support greeting - Technical support
  test_greeting_technical = support_greeting_v2.tests.create!(
    organization_id: acme_corp.id,
    name: "Technical Support Greeting",
    description: "Test greeting for technical support inquiries",
    tags: [ "technical" ],
    enabled: true
  )

  test_greeting_technical.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 10, "max_length" => 500 },
    enabled: true
  )

  puts "  ✓ Created #{PromptTracker::Test.count} tests with #{PromptTracker::EvaluatorConfig.count} evaluator configs"
end

