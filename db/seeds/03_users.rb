# frozen_string_literal: true

# ============================================================================
# USERS
# ============================================================================
puts "\n👤 Creating users..."

admin_user = User.create!(
  email: "admin@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Admin",
  last_name: "User",
  role: "admin",
  confirmed_at: Time.current
)

demo_user = User.create!(
  email: "demo@example.com",
  password: "password123",
  password_confirmation: "password123",
  first_name: "Demo",
  last_name: "User",
  role: "user",
  confirmed_at: Time.current
)

puts "  ✓ Created #{User.count} users"

# Store users for use in other seed files
SeedData.users = {
  admin: admin_user,
  demo: demo_user
}
