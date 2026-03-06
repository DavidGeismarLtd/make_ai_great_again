# frozen_string_literal: true

# ============================================================================
# CLEANUP - Remove existing data
# ============================================================================
puts "\n📦 Cleaning up existing data..."

# Clean up PromptTracker data (order matters due to foreign key constraints)
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_human_evaluations")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_evaluations")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_test_runs")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_tests")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_llm_responses")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_ab_tests")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_evaluator_configs")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_dataset_rows")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_datasets")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_prompt_versions")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_prompts")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_prompt_test_suite_runs")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_prompt_test_suites")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_spans")
ActiveRecord::Base.connection.execute("DELETE FROM prompt_tracker_traces")

# Clean up host app data (order matters due to foreign key constraints)
ApiConfiguration.delete_all
OrganizationMembership.delete_all
OrganizationConfiguration.delete_all
Organization.where.not(slug: 'default').delete_all
User.delete_all

puts "  ✓ Cleanup complete"

