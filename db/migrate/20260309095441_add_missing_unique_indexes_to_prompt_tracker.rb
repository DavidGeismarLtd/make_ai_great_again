class AddMissingUniqueIndexesToPromptTracker < ActiveRecord::Migration[8.1]
  def change
    # ============================================================================
    # Fix unique indexes for acts_as_tenant compatibility
    # ============================================================================
    # When acts_as_tenant is applied to a model with uniqueness validations,
    # the validations are automatically scoped to organization_id.
    # This requires unique indexes that include organization_id.

    # ============================================================================
    # 1. prompt_tracker_prompts - slug and name uniqueness
    # ============================================================================
    # Remove old unique indexes
    remove_index :prompt_tracker_prompts, name: "index_prompt_tracker_prompts_on_slug"
    remove_index :prompt_tracker_prompts, name: "index_prompt_tracker_prompts_on_name"

    # Add new unique indexes scoped to organization_id
    add_index :prompt_tracker_prompts,
              [ :organization_id, :slug ],
              unique: true,
              name: "index_prompts_on_org_and_slug"

    add_index :prompt_tracker_prompts,
              [ :organization_id, :name ],
              unique: true,
              name: "index_prompts_on_org_and_name"

    # ============================================================================
    # 2. prompt_tracker_evaluator_configs - evaluator_type uniqueness
    # ============================================================================
    # Add unique index for evaluator_type scoped to organization_id and configurable
    add_index :prompt_tracker_evaluator_configs,
              [ :organization_id, :evaluator_type, :configurable_type, :configurable_id ],
              unique: true,
              name: "index_evaluator_configs_unique"
  end
end
