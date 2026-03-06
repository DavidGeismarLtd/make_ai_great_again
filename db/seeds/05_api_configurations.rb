# frozen_string_literal: true

# ============================================================================
# API CONFIGURATIONS
# ============================================================================
puts "\n🔑 Creating API configurations..."

acme_corp = SeedData.organizations[:acme_corp]
tech_startup = SeedData.organizations[:tech_startup]

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

