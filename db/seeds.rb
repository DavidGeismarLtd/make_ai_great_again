# frozen_string_literal: true

puts "🌱 Seeding AgentsOnRails database..."

# Temporarily disable tenant requirement for seeding
original_require_tenant = ActsAsTenant.configuration.require_tenant
ActsAsTenant.configuration.require_tenant = false

begin
  # Load the SeedData helper class first
  require_relative 'seeds/seed_data'

  # Load seed files in order
  # Each file is self-contained and handles its own section
  seed_files = [
    '01_cleanup',
    '02_organizations',
    '03_users',
    '04_organization_memberships',
    '05_api_configurations',
    '06_prompt_tracker_agents',
    '07_prompt_tracker_tests',
    '08_prompt_tracker_datasets'
  ]

  seed_files.each do |seed_file|
    require_relative "seeds/#{seed_file}"
  end

  # ============================================================================
  # SUMMARY
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
  puts "  • Agents: #{PromptTracker::Agent.count}"
  puts "  • Agent Versions: #{PromptTracker::AgentVersion.count}"
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
