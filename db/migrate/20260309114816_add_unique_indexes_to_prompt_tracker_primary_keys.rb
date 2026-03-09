class AddUniqueIndexesToPromptTrackerPrimaryKeys < ActiveRecord::Migration[8.1]
  def change
    # Add explicit unique indexes on id (primary key) for PromptTracker tables
    # This is needed for ActiveRecord 8.x compatibility with acts_as_tenant
    # The uniqueness validator checks for unique indexes, and while PostgreSQL
    # creates a unique constraint on the primary key, ActiveRecord's schema_cache
    # doesn't always recognize it as an index.

    # Only add if the index doesn't already exist
    add_index :prompt_tracker_prompts, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_datasets, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_evaluator_configs, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_dataset_rows, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_prompt_versions, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_tests, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_test_runs, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_evaluations, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_human_evaluations, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_llm_responses, :id, unique: true, if_not_exists: true
    add_index :prompt_tracker_ab_tests, :id, unique: true, if_not_exists: true
  end
end
