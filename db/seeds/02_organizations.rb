# frozen_string_literal: true

# ============================================================================
# ORGANIZATIONS
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

# Create OrganizationConfigurations
# Acme Corp: fully configured with real ENV credentials
acme_corp.create_organization_configuration!(
  features_config: {
    "openai_assistant_sync" => true,
    "monitoring" => true,
    "functions" => true
  },
  function_providers_config: {
    "aws_lambda" => {
      "region" => ENV.fetch("AWS_REGION", "us-east-1"),
      "access_key_id" => ENV.fetch("AWS_ACCESS_KEY_ID", ""),
      "secret_access_key" => ENV.fetch("AWS_SECRET_ACCESS_KEY", ""),
      "execution_role_arn" => ENV.fetch("LAMBDA_EXECUTION_ROLE_ARN", ""),
      "function_prefix" => ENV.fetch("LAMBDA_FUNCTION_PREFIX", "prompt-tracker")
    }
  },
  mcp_servers_config: {
    "filesystem" => { "enabled" => true },
    "slack" => {
      "enabled" => true,
      "slack_bot_token" => ENV.fetch("SLACK_BOT_TOKEN", ""),
      "slack_team_id" => ENV.fetch("SLACK_TEAM_ID", "")
    }
  }
)
puts "  ✓ Acme Corp: fully configured (providers, AWS Lambda, MCP filesystem + slack)"

# Tech Startup: only filesystem MCP enabled, defaults for everything else
tech_startup.create_organization_configuration!(
  mcp_servers_config: {
    "filesystem" => { "enabled" => true },
    "slack" => { "enabled" => false, "slack_bot_token" => "", "slack_team_id" => "" }
  }
)
puts "  ✓ Tech Startup: MCP servers configured (filesystem only)"

# Default org: defaults (nothing enabled)
default_org.create_organization_configuration!
puts "  ✓ Default org: default configuration"

# Store organizations for use in other seed files
SeedData.organizations = {
  default: default_org,
  acme_corp: acme_corp,
  tech_startup: tech_startup
}
