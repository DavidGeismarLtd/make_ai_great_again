# frozen_string_literal: true

# ============================================================================
# MONITORING API KEYS
# ============================================================================
puts "\n🔑 Creating Monitoring API keys..."

acme_corp = SeedData.organizations[:acme_corp]
tech_startup = SeedData.organizations[:tech_startup]

# Create monitoring API keys for Acme Corp
ActsAsTenant.with_tenant(acme_corp) do
  production_key = MonitoringApiKey.create!(
    name: "Production",
    created_by: "admin@example.com"
  )
  puts "  ✓ Acme Corp - Production key: #{production_key.raw_token}"

  staging_key = MonitoringApiKey.create!(
    name: "Staging",
    created_by: "admin@example.com"
  )
  puts "  ✓ Acme Corp - Staging key:    #{staging_key.raw_token}"

  SeedData.monitoring_api_keys = {
    acme_production: production_key,
    acme_staging: staging_key
  }
end

# Create monitoring API key for Tech Startup
ActsAsTenant.with_tenant(tech_startup) do
  key = MonitoringApiKey.create!(
    name: "Default",
    created_by: "demo@example.com"
  )
  puts "  ✓ Tech Startup - Default key:  #{key.raw_token}"

  SeedData.monitoring_api_keys[:tech_startup_default] = key
end

puts "  ✓ Created #{MonitoringApiKey.count} monitoring API keys"
