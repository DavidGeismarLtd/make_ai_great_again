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
    '08_prompt_tracker_datasets',
    '09_monitoring_api_keys',
    '10_function_definitions'
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
  puts "  • Monitoring API Keys: #{MonitoringApiKey.count}"
  puts ""
  puts "🤖 PromptTracker Data:"
  puts "  • Agents: #{PromptTracker::Agent.count}"
  puts "  • Agent Versions: #{PromptTracker::AgentVersion.count}"
  puts "  • Tests: #{PromptTracker::Test.count}"
  puts "  • Evaluator Configs: #{PromptTracker::EvaluatorConfig.count}"
  puts "  • Datasets: #{PromptTracker::Dataset.count}"
  puts "  • Dataset Rows: #{PromptTracker::DatasetRow.count}"
  puts "  • Function Definitions: #{PromptTracker::FunctionDefinition.count}"
  puts ""
  puts "🔐 User Accounts:"
  puts "-" * 80
  puts "  %-30s %-15s %-10s %s" % [ "EMAIL", "PASSWORD", "ROLE", "ORGANIZATIONS" ]
  puts "-" * 80
  User.find_each do |user|
    memberships = user.organization_memberships.includes(:organization).map do |m|
      "#{m.organization.name} (#{m.role})"
    end
    puts "  %-30s %-15s %-10s %s" % [
      user.email,
      "password123",
      user.role,
      memberships.join(", ")
    ]
  end
  puts "-" * 80
  puts ""
  puts "=" * 80
ensure
  # Restore original tenant requirement setting
  ActsAsTenant.configuration.require_tenant = original_require_tenant
end
