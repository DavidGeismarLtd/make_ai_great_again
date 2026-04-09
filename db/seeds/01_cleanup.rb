# frozen_string_literal: true

# ============================================================================
# CLEANUP - Remove existing data
# ============================================================================
puts "\n📦 Cleaning up existing data..."

connection = ActiveRecord::Base.connection

delete_if_table_exists = lambda do |table_name|
  next unless connection.table_exists?(table_name)

  connection.execute("DELETE FROM #{connection.quote_table_name(table_name)}")
end

# Clean up PromptTracker data (order matters due to foreign key constraints)
delete_if_table_exists.call(:prompt_tracker_human_evaluations)
delete_if_table_exists.call(:prompt_tracker_evaluations)
delete_if_table_exists.call(:prompt_tracker_test_runs)
delete_if_table_exists.call(:prompt_tracker_tests)
delete_if_table_exists.call(:prompt_tracker_llm_responses)
delete_if_table_exists.call(:prompt_tracker_ab_tests)
delete_if_table_exists.call(:prompt_tracker_evaluator_configs)
delete_if_table_exists.call(:prompt_tracker_dataset_rows)
delete_if_table_exists.call(:prompt_tracker_datasets)
delete_if_table_exists.call(:prompt_tracker_agent_versions)
delete_if_table_exists.call(:prompt_tracker_agents)
delete_if_table_exists.call(:prompt_tracker_prompt_test_suite_runs)
delete_if_table_exists.call(:prompt_tracker_prompt_test_suites)
delete_if_table_exists.call(:prompt_tracker_spans)
delete_if_table_exists.call(:prompt_tracker_traces)

# Clean up host app data (order matters due to foreign key constraints)
MonitoringApiKey.delete_all
ApiConfiguration.delete_all
OrganizationMembership.delete_all
OrganizationConfiguration.delete_all
Organization.where.not(slug: 'default').delete_all
User.delete_all

puts "  ✓ Cleanup complete"
