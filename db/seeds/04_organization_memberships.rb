# frozen_string_literal: true

# ============================================================================
# ORGANIZATION MEMBERSHIPS
# ============================================================================
puts "\n👥 Creating organization memberships..."

acme_corp = SeedData.organizations[:acme_corp]
tech_startup = SeedData.organizations[:tech_startup]
admin_user = SeedData.users[:admin]
demo_user = SeedData.users[:demo]

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

