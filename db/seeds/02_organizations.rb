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

# Store organizations for use in other seed files
SeedData.organizations = {
  default: default_org,
  acme_corp: acme_corp,
  tech_startup: tech_startup
}

