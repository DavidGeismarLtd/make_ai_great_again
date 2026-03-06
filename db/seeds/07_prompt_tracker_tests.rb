# frozen_string_literal: true

# ============================================================================
# PROMPTTRACKER - TESTS & EVALUATORS
# ============================================================================
puts "\n🧪 Creating PromptTracker tests and evaluators..."

acme_corp = SeedData.organizations[:acme_corp]

# Set tenant context for PromptTracker data creation
ActsAsTenant.with_tenant(acme_corp) do
  # Get prompt versions
  support_greeting_v3 = SeedData.prompt_versions[:support_greeting_v3]
  email_summary_v1 = SeedData.prompt_versions[:email_summary_v1]
  code_review_v1 = SeedData.prompt_versions[:code_review_v1]

  # ============================================================================
  # 1. Basic Tests for Customer Support Greeting
  # ============================================================================
  puts "  Creating basic tests for customer support..."

  # Test 1: Premium Customer Greeting
  test_premium = support_greeting_v3.tests.create!(
    organization_id: acme_corp.id,
    name: "Premium Customer Greeting",
    description: "Test greeting for premium customers with billing issues",
    tags: [ "premium", "billing" ],
    enabled: true
  )

  test_premium.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: { patterns: [ "John Smith", "billing" ], match_all: true }
  )

  test_premium.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 10, "max_length" => 500 },
    enabled: true
  )

  # Test 2: Technical Support Greeting
  test_technical = support_greeting_v3.tests.create!(
    organization_id: acme_corp.id,
    name: "Technical Support Greeting",
    description: "Test greeting for technical support inquiries",
    tags: [ "technical" ],
    enabled: true
  )

  test_technical.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: { patterns: [ "Sarah Johnson", "technical" ], match_all: true }
  )

  test_technical.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 10, "max_length" => 500 },
    enabled: true
  )

  # Test 3: Account Issue Greeting
  test_account = support_greeting_v3.tests.create!(
    organization_id: acme_corp.id,
    name: "Account Issue Greeting",
    description: "Test greeting for account-related questions",
    tags: [ "account" ],
    enabled: true
  )

  test_account.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: { patterns: [ "Mike Davis", "account" ], match_all: true }
  )

  test_account.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 10, "max_length" => 500 },
    enabled: true
  )

  # Test 4: General Inquiry Greeting
  test_general = support_greeting_v3.tests.create!(
    organization_id: acme_corp.id,
    name: "General Inquiry Greeting",
    description: "Test greeting for general customer inquiries",
    tags: [ "general" ],
    enabled: true
  )

  test_general.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: { patterns: [ "Emily Chen", "general" ], match_all: true }
  )

  test_general.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 10, "max_length" => 500 },
    enabled: true
  )

  # Test 5: Edge Case - Disabled test
  test_edge = support_greeting_v3.tests.create!(
    organization_id: acme_corp.id,
    name: "Edge Case - Very Long Name",
    description: "Test greeting with unusually long customer name",
    tags: [ "edge-case" ],
    enabled: false
  )

  test_edge.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: { patterns: [ "Alexander", "billing" ], match_all: true }
  )

  puts "  ✓ Created basic tests (5 tests with simple evaluators)"

  # ============================================================================
  # 2. Advanced Tests with Multiple Evaluators
  # ============================================================================
  puts "  Creating advanced tests with multiple evaluators..."

  # Test 6: Comprehensive Quality Check
  test_comprehensive = support_greeting_v3.tests.create!(
    organization_id: acme_corp.id,
    name: "Comprehensive Quality Check",
    description: "Tests greeting quality with multiple evaluators including LLM judge, length, and keyword checks",
    tags: [ "comprehensive", "quality", "critical" ],
    enabled: true
  )

  test_comprehensive.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: {
      patterns: [
        "Jennifer",
        "refund",
        "\\b(help|assist|support)\\b",
        "^Hi\\s+\\w+"
      ],
      match_all: true
    }
  )

  test_comprehensive.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 50, "max_length" => 200 },
    enabled: true
  )

  test_comprehensive.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::KeywordEvaluator",
    config: {
      "required_keywords" => [ "help", "refund" ],
      "forbidden_keywords" => [ "unfortunately", "cannot", "unable" ],
      "case_sensitive" => false
    },
    enabled: true
  )

  test_comprehensive.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LlmJudgeEvaluator",
    config: {
      "judge_model" => "gpt-4o",
      "custom_instructions" => "Evaluate if the greeting is warm, professional, and acknowledges the customer's refund request appropriately. Consider helpfulness, professionalism, clarity, and tone."
    },
    enabled: true
  )

  # Test 7: Email Summary Format Validation
  test_email_format = email_summary_v1.tests.create!(
    organization_id: acme_corp.id,
    name: "Email Summary Format Validation",
    description: "Validates email summary format with complex regex patterns",
    tags: [ "format", "validation", "email" ],
    enabled: true
  )

  test_email_format.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: {
      patterns: [
        "\\b(discuss|planning|goals?)\\b",
        "\\b(Q4|quarter|fourth quarter)\\b",
        "^[A-Z]",
        "\\.$"
      ],
      match_all: true
    }
  )

  test_email_format.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 100, "max_length" => 400 },
    enabled: true
  )

  test_email_format.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LlmJudgeEvaluator",
    config: {
      "judge_model" => "gpt-4o",
      "custom_instructions" => "Evaluate if the summary captures the key points of the email thread concisely and accurately. Consider accuracy, conciseness, and completeness."
    },
    enabled: true
  )

  # Test 8: Code Review Quality Assessment
  test_code_quality = code_review_v1.tests.create!(
    organization_id: acme_corp.id,
    name: "Code Review Quality Assessment",
    description: "Tests code review feedback quality with LLM judge and keyword validation",
    tags: [ "code-review", "quality", "technical" ],
    enabled: true
  )

  test_code_quality.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::PatternMatchEvaluator",
    enabled: true,
    config: {
      patterns: [
        "\\b(quality|readability|performance|best practice)\\b",
        "\\b(bug|edge case|error|exception)\\b",
        "\\b(consider|suggest|recommend|improve)\\b",
        "```ruby"
      ],
      match_all: true
    }
  )

  test_code_quality.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
    config: { "min_length" => 200, "max_length" => 1000 },
    enabled: true
  )

  test_code_quality.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::KeywordEvaluator",
    config: {
      "required_keywords" => [ "code", "quality", "readability" ],
      "forbidden_keywords" => [ "terrible", "awful", "stupid" ],
      "case_sensitive" => false
    },
    enabled: true
  )

  test_code_quality.evaluator_configs.create!(
    organization_id: acme_corp.id,
    evaluator_type: "PromptTracker::Evaluators::LlmJudgeEvaluator",
    config: {
      "judge_model" => "gpt-4o",
      "custom_instructions" => "Evaluate if the code review is constructive, technically accurate, and provides actionable feedback. The review should identify potential issues and suggest improvements. Consider helpfulness, technical accuracy, professionalism, and completeness."
    },
    enabled: true
  )

  puts "  ✓ Created advanced tests (3 tests with multiple evaluators)"

  # Store for use in other seed files
  SeedData.tests = {
    test_premium: test_premium,
    test_technical: test_technical,
    test_account: test_account,
    test_general: test_general,
    test_edge: test_edge,
    test_comprehensive: test_comprehensive,
    test_email_format: test_email_format,
    test_code_quality: test_code_quality
  }

  puts "\n  ✅ Total: #{PromptTracker::Test.count} tests with #{PromptTracker::EvaluatorConfig.count} evaluator configs"
end
