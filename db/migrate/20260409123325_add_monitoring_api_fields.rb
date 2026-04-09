# frozen_string_literal: true

# Adds fields required by the Monitoring API:
# 1. external_id columns on traces, spans, llm_responses for SDK idempotency
# 2. Makes agent_version_id and rendered_prompt nullable on llm_responses
#    (external SDK calls won't always have an agent configured)
# 3. Adds llm_response_id to spans for direct span→llm_response linking
class AddMonitoringApiFields < ActiveRecord::Migration[8.1]
  def change
    # --- external_id columns for idempotency ---
    add_column :prompt_tracker_traces, :external_id, :string
    add_index :prompt_tracker_traces, [ :organization_id, :external_id ],
              unique: true, name: "index_traces_on_org_and_external_id",
              where: "external_id IS NOT NULL"

    add_column :prompt_tracker_spans, :external_id, :string
    add_index :prompt_tracker_spans, [ :organization_id, :external_id ],
              unique: true, name: "index_spans_on_org_and_external_id",
              where: "external_id IS NOT NULL"

    add_column :prompt_tracker_llm_responses, :external_id, :string
    add_index :prompt_tracker_llm_responses, [ :organization_id, :external_id ],
              unique: true, name: "index_llm_responses_on_org_and_external_id",
              where: "external_id IS NOT NULL"

    # --- Make agent_version_id nullable for API-ingested LLM responses ---
    change_column_null :prompt_tracker_llm_responses, :agent_version_id, true

    # --- Make rendered_prompt nullable for API-ingested LLM responses ---
    change_column_null :prompt_tracker_llm_responses, :rendered_prompt, true

    # --- Add llm_response_id to spans for direct linking ---
    add_column :prompt_tracker_spans, :llm_response_id, :bigint
    add_index :prompt_tracker_spans, :llm_response_id
  end
end
