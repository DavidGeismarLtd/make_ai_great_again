class AddOrganizationIdToPromptTrackerTables < ActiveRecord::Migration[8.1]
  def up
    # Step 1: Add organization_id as nullable with index
    organization_tables.each do |table|
      add_reference table, :organization, null: true, index: true
    end

    # Step 2: Get or create a default organization for existing data
    default_org = Organization.find_or_create_by!(slug: 'default') do |org|
      org.name = 'Default Organization'
      org.status = 'active'
    end

    # Step 3: Update all existing records to use the default organization
    organization_tables.each do |table|
      execute "UPDATE #{table} SET organization_id = #{default_org.id} WHERE organization_id IS NULL"
    end

    # Step 4: Make organization_id non-nullable and add foreign keys
    organization_tables.each do |table|
      change_column_null table, :organization_id, false
      add_foreign_key table, :organizations
    end

    audit_tables.each do |table|
      add_reference table, :user, null: true, foreign_key: true
    end
  end

  def down
    audit_tables.each do |table|
      remove_reference table, :user, foreign_key: true
    end

    organization_tables.each do |table|
      remove_foreign_key table, :organizations
      remove_reference table, :organization, index: true
    end
  end

  private

  def organization_tables
    [
      :prompt_tracker_agents,
      :prompt_tracker_agent_versions,
      :prompt_tracker_tests,
      :prompt_tracker_test_runs,
      :prompt_tracker_prompt_test_suites,
      :prompt_tracker_prompt_test_suite_runs,
      :prompt_tracker_datasets,
      :prompt_tracker_dataset_rows,
      :prompt_tracker_evaluations,
      :prompt_tracker_evaluator_configs,
      :prompt_tracker_human_evaluations,
      :prompt_tracker_llm_responses,
      :prompt_tracker_traces,
      :prompt_tracker_spans,
      :prompt_tracker_ab_tests,
      :prompt_tracker_function_definitions,
      :prompt_tracker_environment_variables,
      :prompt_tracker_deployed_agents,
      :prompt_tracker_agent_conversations,
      :prompt_tracker_task_runs,
      :prompt_tracker_task_schedules,
      :prompt_tracker_function_executions
    ]
  end

  def audit_tables
    [
      :prompt_tracker_agents,
      :prompt_tracker_agent_versions,
      :prompt_tracker_tests,
      :prompt_tracker_test_runs,
      :prompt_tracker_datasets,
      :prompt_tracker_dataset_rows,
      :prompt_tracker_human_evaluations
    ]
  end
end
