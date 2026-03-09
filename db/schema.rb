# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_09_230955) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "api_configurations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "encrypted_api_key"
    t.boolean "is_active", default: true
    t.string "key_name", null: false
    t.datetime "last_validated_at"
    t.bigint "organization_id", null: false
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "provider", "key_name"], name: "index_api_configs_on_org_provider_name", unique: true
    t.index ["organization_id"], name: "index_api_configurations_on_organization_id"
  end

  create_table "organization_configurations", force: :cascade do |t|
    t.jsonb "contexts_config", default: {}, null: false
    t.datetime "created_at", null: false
    t.jsonb "features_config", default: {}, null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_organization_configurations_on_organization_id", unique: true
  end

  create_table "organization_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id", "user_id"], name: "index_org_memberships_on_org_and_user", unique: true
    t.index ["organization_id"], name: "index_organization_memberships_on_organization_id"
    t.index ["user_id"], name: "index_organization_memberships_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
  end

  create_table "prompt_tracker_ab_tests", force: :cascade do |t|
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.float "confidence_level", default: 0.95
    t.datetime "created_at", null: false
    t.string "created_by"
    t.text "description"
    t.string "hypothesis"
    t.jsonb "metadata", default: {}
    t.string "metric_to_optimize", null: false
    t.float "minimum_detectable_effect", default: 0.05
    t.integer "minimum_sample_size", default: 100
    t.string "name", null: false
    t.string "optimization_direction", default: "minimize", null: false
    t.bigint "organization_id", null: false
    t.bigint "prompt_id", null: false
    t.jsonb "results", default: {}
    t.datetime "started_at"
    t.string "status", default: "draft", null: false
    t.jsonb "traffic_split", default: {}, null: false
    t.datetime "updated_at", null: false
    t.jsonb "variants", default: [], null: false
    t.index ["completed_at"], name: "index_prompt_tracker_ab_tests_on_completed_at"
    t.index ["id"], name: "index_prompt_tracker_ab_tests_on_id", unique: true
    t.index ["metric_to_optimize"], name: "index_prompt_tracker_ab_tests_on_metric_to_optimize"
    t.index ["organization_id"], name: "index_prompt_tracker_ab_tests_on_organization_id"
    t.index ["prompt_id", "status"], name: "index_prompt_tracker_ab_tests_on_prompt_id_and_status"
    t.index ["prompt_id"], name: "index_prompt_tracker_ab_tests_on_prompt_id"
    t.index ["started_at"], name: "index_prompt_tracker_ab_tests_on_started_at"
    t.index ["status"], name: "index_prompt_tracker_ab_tests_on_status"
  end

  create_table "prompt_tracker_dataset_rows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "dataset_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "organization_id", null: false
    t.jsonb "row_data", default: {}, null: false
    t.string "source", default: "manual", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_prompt_tracker_dataset_rows_on_created_at"
    t.index ["dataset_id"], name: "index_prompt_tracker_dataset_rows_on_dataset_id"
    t.index ["id"], name: "index_prompt_tracker_dataset_rows_on_id", unique: true
    t.index ["organization_id"], name: "index_prompt_tracker_dataset_rows_on_organization_id"
    t.index ["source"], name: "index_prompt_tracker_dataset_rows_on_source"
  end

  create_table "prompt_tracker_datasets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "created_by"
    t.integer "dataset_type", default: 0, null: false
    t.text "description"
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.jsonb "schema", default: [], null: false
    t.bigint "testable_id"
    t.string "testable_type"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_prompt_tracker_datasets_on_created_at"
    t.index ["dataset_type"], name: "index_prompt_tracker_datasets_on_dataset_type"
    t.index ["id"], name: "index_prompt_tracker_datasets_on_id", unique: true
    t.index ["organization_id", "name", "testable_type", "testable_id"], name: "index_datasets_on_org_name_testable", unique: true
    t.index ["organization_id"], name: "index_prompt_tracker_datasets_on_organization_id"
    t.index ["testable_type", "testable_id"], name: "index_prompt_tracker_datasets_on_testable_type_and_testable_id"
  end

  create_table "prompt_tracker_evaluations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "evaluation_context", default: "tracked_call", null: false
    t.bigint "evaluator_config_id"
    t.string "evaluator_id"
    t.string "evaluator_type", null: false
    t.text "feedback"
    t.bigint "llm_response_id"
    t.jsonb "metadata", default: {}
    t.bigint "organization_id", null: false
    t.boolean "passed"
    t.decimal "score", precision: 10, scale: 2, null: false
    t.decimal "score_max", precision: 10, scale: 2, default: "5.0"
    t.decimal "score_min", precision: 10, scale: 2, default: "0.0"
    t.bigint "test_run_id"
    t.datetime "updated_at", null: false
    t.index ["evaluation_context"], name: "index_prompt_tracker_evaluations_on_evaluation_context"
    t.index ["evaluator_config_id"], name: "index_prompt_tracker_evaluations_on_evaluator_config_id"
    t.index ["evaluator_type", "created_at"], name: "index_evaluations_on_type_and_created_at"
    t.index ["evaluator_type"], name: "index_prompt_tracker_evaluations_on_evaluator_type"
    t.index ["id"], name: "index_prompt_tracker_evaluations_on_id", unique: true
    t.index ["llm_response_id"], name: "index_prompt_tracker_evaluations_on_llm_response_id"
    t.index ["organization_id"], name: "index_prompt_tracker_evaluations_on_organization_id"
    t.index ["score"], name: "index_evaluations_on_score"
    t.index ["test_run_id"], name: "index_prompt_tracker_evaluations_on_test_run_id"
  end

  create_table "prompt_tracker_evaluator_configs", force: :cascade do |t|
    t.jsonb "config", default: {}, null: false
    t.bigint "configurable_id", null: false
    t.string "configurable_type", null: false
    t.datetime "created_at", null: false
    t.string "depends_on"
    t.boolean "enabled", default: true, null: false
    t.string "evaluator_key"
    t.string "evaluator_type", null: false
    t.bigint "organization_id", null: false
    t.integer "priority"
    t.decimal "threshold_score", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["configurable_type", "configurable_id"], name: "index_evaluator_configs_on_configurable"
    t.index ["depends_on"], name: "index_prompt_tracker_evaluator_configs_on_depends_on"
    t.index ["enabled"], name: "index_prompt_tracker_evaluator_configs_on_enabled"
    t.index ["id"], name: "index_prompt_tracker_evaluator_configs_on_id", unique: true
    t.index ["organization_id", "evaluator_type", "configurable_type", "configurable_id"], name: "index_evaluator_configs_unique", unique: true
    t.index ["organization_id"], name: "index_prompt_tracker_evaluator_configs_on_organization_id"
  end

  create_table "prompt_tracker_human_evaluations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "evaluation_id"
    t.text "feedback"
    t.bigint "llm_response_id"
    t.bigint "organization_id", null: false
    t.decimal "score", precision: 10, scale: 2, null: false
    t.bigint "test_run_id"
    t.datetime "updated_at", null: false
    t.index ["evaluation_id"], name: "index_prompt_tracker_human_evaluations_on_evaluation_id"
    t.index ["id"], name: "index_prompt_tracker_human_evaluations_on_id", unique: true
    t.index ["llm_response_id"], name: "index_prompt_tracker_human_evaluations_on_llm_response_id"
    t.index ["organization_id"], name: "index_prompt_tracker_human_evaluations_on_organization_id"
    t.index ["test_run_id"], name: "index_prompt_tracker_human_evaluations_on_test_run_id"
    t.check_constraint "evaluation_id IS NOT NULL AND llm_response_id IS NULL AND test_run_id IS NULL OR evaluation_id IS NULL AND llm_response_id IS NOT NULL AND test_run_id IS NULL OR evaluation_id IS NULL AND llm_response_id IS NULL AND test_run_id IS NOT NULL", name: "human_evaluation_belongs_to_one"
  end

  create_table "prompt_tracker_llm_responses", force: :cascade do |t|
    t.bigint "ab_test_id"
    t.string "ab_variant"
    t.jsonb "context", default: {}
    t.string "conversation_id"
    t.decimal "cost_usd", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.string "environment"
    t.text "error_message"
    t.string "error_type"
    t.string "model", null: false
    t.bigint "organization_id", null: false
    t.string "previous_response_id"
    t.bigint "prompt_version_id", null: false
    t.string "provider", null: false
    t.text "rendered_prompt", null: false
    t.text "rendered_system_prompt"
    t.string "response_id"
    t.jsonb "response_metadata", default: {}
    t.text "response_text"
    t.integer "response_time_ms"
    t.string "session_id"
    t.bigint "span_id"
    t.string "status", default: "pending", null: false
    t.integer "tokens_completion"
    t.integer "tokens_prompt"
    t.integer "tokens_total"
    t.jsonb "tool_outputs", default: {}
    t.jsonb "tools_used", default: []
    t.bigint "trace_id"
    t.integer "turn_number"
    t.datetime "updated_at", null: false
    t.string "user_id"
    t.jsonb "variables_used", default: {}
    t.index ["ab_test_id", "ab_variant"], name: "index_llm_responses_on_ab_test_and_variant"
    t.index ["ab_test_id"], name: "index_prompt_tracker_llm_responses_on_ab_test_id"
    t.index ["conversation_id", "turn_number"], name: "index_llm_responses_on_conversation_turn"
    t.index ["conversation_id"], name: "index_prompt_tracker_llm_responses_on_conversation_id"
    t.index ["environment"], name: "index_prompt_tracker_llm_responses_on_environment"
    t.index ["id"], name: "index_prompt_tracker_llm_responses_on_id", unique: true
    t.index ["model"], name: "index_prompt_tracker_llm_responses_on_model"
    t.index ["organization_id"], name: "index_prompt_tracker_llm_responses_on_organization_id"
    t.index ["previous_response_id"], name: "index_prompt_tracker_llm_responses_on_previous_response_id"
    t.index ["prompt_version_id"], name: "index_prompt_tracker_llm_responses_on_prompt_version_id"
    t.index ["provider", "model", "created_at"], name: "index_llm_responses_on_provider_model_created_at"
    t.index ["provider"], name: "index_prompt_tracker_llm_responses_on_provider"
    t.index ["response_id"], name: "index_prompt_tracker_llm_responses_on_response_id", unique: true, where: "(response_id IS NOT NULL)"
    t.index ["session_id"], name: "index_prompt_tracker_llm_responses_on_session_id"
    t.index ["span_id"], name: "index_prompt_tracker_llm_responses_on_span_id"
    t.index ["status", "created_at"], name: "index_llm_responses_on_status_and_created_at"
    t.index ["status"], name: "index_prompt_tracker_llm_responses_on_status"
    t.index ["tools_used"], name: "index_prompt_tracker_llm_responses_on_tools_used", using: :gin
    t.index ["trace_id"], name: "index_prompt_tracker_llm_responses_on_trace_id"
    t.index ["user_id"], name: "index_prompt_tracker_llm_responses_on_user_id"
  end

  create_table "prompt_tracker_prompt_test_suite_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "error_tests", default: 0, null: false
    t.integer "failed_tests", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "organization_id", null: false
    t.integer "passed_tests", default: 0, null: false
    t.bigint "prompt_test_suite_id", null: false
    t.integer "skipped_tests", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.decimal "total_cost_usd", precision: 10, scale: 6
    t.integer "total_duration_ms"
    t.integer "total_tests", default: 0, null: false
    t.string "triggered_by"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_prompt_tracker_prompt_test_suite_runs_on_created_at"
    t.index ["organization_id"], name: "index_prompt_tracker_prompt_test_suite_runs_on_organization_id"
    t.index ["prompt_test_suite_id", "created_at"], name: "idx_on_prompt_test_suite_id_created_at_00b03ff2b9"
    t.index ["prompt_test_suite_id"], name: "idx_on_prompt_test_suite_id_4251a091be"
    t.index ["status"], name: "index_prompt_tracker_prompt_test_suite_runs_on_status"
  end

  create_table "prompt_tracker_prompt_test_suites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "enabled", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.bigint "prompt_id"
    t.jsonb "tags", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_prompt_tracker_prompt_test_suites_on_enabled"
    t.index ["name"], name: "index_prompt_tracker_prompt_test_suites_on_name", unique: true
    t.index ["organization_id"], name: "index_prompt_tracker_prompt_test_suites_on_organization_id"
    t.index ["prompt_id"], name: "index_prompt_tracker_prompt_test_suites_on_prompt_id"
    t.index ["tags"], name: "index_prompt_tracker_prompt_test_suites_on_tags", using: :gin
  end

  create_table "prompt_tracker_prompt_versions", force: :cascade do |t|
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.jsonb "model_config", default: {}
    t.text "notes"
    t.bigint "organization_id", null: false
    t.bigint "prompt_id", null: false
    t.jsonb "response_schema"
    t.string "status", default: "draft", null: false
    t.text "system_prompt"
    t.datetime "updated_at", null: false
    t.text "user_prompt", null: false
    t.jsonb "variables_schema", default: []
    t.integer "version_number", null: false
    t.index ["archived_at"], name: "index_prompt_tracker_prompt_versions_on_archived_at"
    t.index ["id"], name: "index_prompt_tracker_prompt_versions_on_id", unique: true
    t.index ["organization_id"], name: "index_prompt_tracker_prompt_versions_on_organization_id"
    t.index ["prompt_id", "status"], name: "index_prompt_versions_on_prompt_and_status"
    t.index ["prompt_id", "version_number"], name: "index_prompt_versions_on_prompt_and_version_number", unique: true
    t.index ["prompt_id"], name: "index_prompt_tracker_prompt_versions_on_prompt_id"
    t.index ["status"], name: "index_prompt_tracker_prompt_versions_on_status"
  end

  create_table "prompt_tracker_prompts", force: :cascade do |t|
    t.datetime "archived_at"
    t.string "category"
    t.datetime "created_at", null: false
    t.string "created_by"
    t.text "description"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "score_aggregation_strategy", default: "weighted_average"
    t.string "slug", null: false
    t.jsonb "tags", default: []
    t.datetime "updated_at", null: false
    t.index ["archived_at"], name: "index_prompt_tracker_prompts_on_archived_at"
    t.index ["category"], name: "index_prompt_tracker_prompts_on_category"
    t.index ["id"], name: "index_prompt_tracker_prompts_on_id", unique: true
    t.index ["organization_id", "name"], name: "index_prompts_on_org_and_name", unique: true
    t.index ["organization_id", "slug"], name: "index_prompts_on_org_and_slug", unique: true
    t.index ["organization_id"], name: "index_prompt_tracker_prompts_on_organization_id"
    t.index ["score_aggregation_strategy"], name: "index_prompts_on_aggregation_strategy"
  end

  create_table "prompt_tracker_spans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.datetime "ended_at"
    t.text "input"
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.text "output"
    t.bigint "parent_span_id"
    t.string "span_type"
    t.datetime "started_at", null: false
    t.string "status", default: "running", null: false
    t.bigint "trace_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_prompt_tracker_spans_on_organization_id"
    t.index ["parent_span_id"], name: "index_prompt_tracker_spans_on_parent_span_id"
    t.index ["span_type"], name: "index_prompt_tracker_spans_on_span_type"
    t.index ["status", "created_at"], name: "index_prompt_tracker_spans_on_status_and_created_at"
    t.index ["trace_id"], name: "index_prompt_tracker_spans_on_trace_id"
  end

  create_table "prompt_tracker_test_runs", force: :cascade do |t|
    t.jsonb "assertion_results", default: {}, null: false
    t.decimal "cost_usd", precision: 10, scale: 6
    t.datetime "created_at", null: false
    t.bigint "dataset_id"
    t.bigint "dataset_row_id"
    t.text "error_message"
    t.jsonb "evaluator_results", default: [], null: false
    t.integer "execution_time_ms"
    t.integer "failed_evaluators", default: 0, null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "organization_id", null: false
    t.jsonb "output_data"
    t.boolean "passed"
    t.integer "passed_evaluators", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.bigint "test_id", null: false
    t.integer "total_evaluators", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_prompt_tracker_test_runs_on_created_at"
    t.index ["id"], name: "index_prompt_tracker_test_runs_on_id", unique: true
    t.index ["organization_id"], name: "index_prompt_tracker_test_runs_on_organization_id"
    t.index ["output_data"], name: "index_prompt_tracker_test_runs_on_output_data", using: :gin
    t.index ["passed"], name: "index_prompt_tracker_test_runs_on_passed"
    t.index ["status"], name: "index_prompt_tracker_test_runs_on_status"
    t.index ["test_id"], name: "index_prompt_tracker_test_runs_on_test_id"
  end

  create_table "prompt_tracker_tests", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "enabled", default: true, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.jsonb "tags", default: [], null: false
    t.bigint "testable_id"
    t.string "testable_type"
    t.datetime "updated_at", null: false
    t.index ["enabled"], name: "index_prompt_tracker_tests_on_enabled"
    t.index ["id"], name: "index_prompt_tracker_tests_on_id", unique: true
    t.index ["name"], name: "index_prompt_tracker_tests_on_name"
    t.index ["organization_id"], name: "index_prompt_tracker_tests_on_organization_id"
    t.index ["tags"], name: "index_prompt_tracker_tests_on_tags", using: :gin
    t.index ["testable_type", "testable_id"], name: "index_prompt_tracker_tests_on_testable_type_and_testable_id"
  end

  create_table "prompt_tracker_traces", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.datetime "ended_at"
    t.text "input"
    t.jsonb "metadata", default: {}
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.text "output"
    t.string "session_id"
    t.datetime "started_at", null: false
    t.string "status", default: "running", null: false
    t.datetime "updated_at", null: false
    t.string "user_id"
    t.index ["organization_id"], name: "index_prompt_tracker_traces_on_organization_id"
    t.index ["session_id"], name: "index_prompt_tracker_traces_on_session_id"
    t.index ["started_at"], name: "index_prompt_tracker_traces_on_started_at"
    t.index ["status", "created_at"], name: "index_prompt_tracker_traces_on_status_and_created_at"
    t.index ["user_id"], name: "index_prompt_tracker_traces_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "api_configurations", "organizations"
  add_foreign_key "organization_configurations", "organizations"
  add_foreign_key "organization_memberships", "organizations"
  add_foreign_key "organization_memberships", "users"
  add_foreign_key "prompt_tracker_ab_tests", "organizations"
  add_foreign_key "prompt_tracker_ab_tests", "prompt_tracker_prompts", column: "prompt_id"
  add_foreign_key "prompt_tracker_dataset_rows", "organizations"
  add_foreign_key "prompt_tracker_dataset_rows", "prompt_tracker_datasets", column: "dataset_id"
  add_foreign_key "prompt_tracker_datasets", "organizations"
  add_foreign_key "prompt_tracker_evaluations", "organizations"
  add_foreign_key "prompt_tracker_evaluations", "prompt_tracker_test_runs", column: "test_run_id"
  add_foreign_key "prompt_tracker_evaluator_configs", "organizations"
  add_foreign_key "prompt_tracker_human_evaluations", "organizations"
  add_foreign_key "prompt_tracker_human_evaluations", "prompt_tracker_evaluations", column: "evaluation_id"
  add_foreign_key "prompt_tracker_human_evaluations", "prompt_tracker_llm_responses", column: "llm_response_id"
  add_foreign_key "prompt_tracker_human_evaluations", "prompt_tracker_test_runs", column: "test_run_id"
  add_foreign_key "prompt_tracker_llm_responses", "organizations"
  add_foreign_key "prompt_tracker_llm_responses", "prompt_tracker_ab_tests", column: "ab_test_id"
  add_foreign_key "prompt_tracker_llm_responses", "prompt_tracker_prompt_versions", column: "prompt_version_id"
  add_foreign_key "prompt_tracker_llm_responses", "prompt_tracker_spans", column: "span_id"
  add_foreign_key "prompt_tracker_llm_responses", "prompt_tracker_traces", column: "trace_id"
  add_foreign_key "prompt_tracker_prompt_test_suite_runs", "organizations"
  add_foreign_key "prompt_tracker_prompt_test_suites", "organizations"
  add_foreign_key "prompt_tracker_prompt_versions", "organizations"
  add_foreign_key "prompt_tracker_prompt_versions", "prompt_tracker_prompts", column: "prompt_id"
  add_foreign_key "prompt_tracker_prompts", "organizations"
  add_foreign_key "prompt_tracker_spans", "organizations"
  add_foreign_key "prompt_tracker_spans", "prompt_tracker_spans", column: "parent_span_id"
  add_foreign_key "prompt_tracker_spans", "prompt_tracker_traces", column: "trace_id"
  add_foreign_key "prompt_tracker_test_runs", "organizations"
  add_foreign_key "prompt_tracker_test_runs", "prompt_tracker_dataset_rows", column: "dataset_row_id"
  add_foreign_key "prompt_tracker_test_runs", "prompt_tracker_datasets", column: "dataset_id"
  add_foreign_key "prompt_tracker_test_runs", "prompt_tracker_tests", column: "test_id"
  add_foreign_key "prompt_tracker_tests", "organizations"
  add_foreign_key "prompt_tracker_traces", "organizations"
end
