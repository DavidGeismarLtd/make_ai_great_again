# frozen_string_literal: true

# Creates the monitoring_api_keys table for SDK authentication.
# These keys allow external applications to send monitoring data
# (traces, spans, LLM responses) via the REST API.
class CreateMonitoringApiKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :monitoring_api_keys do |t|
      t.bigint :organization_id, null: false
      t.string :name, null: false
      t.string :token_digest, null: false
      t.string :token_prefix, null: false
      t.string :status, null: false, default: "active"
      t.datetime :last_used_at
      t.string :created_by
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :monitoring_api_keys, :organization_id
    add_index :monitoring_api_keys, :token_digest, unique: true
    add_index :monitoring_api_keys, :status
    add_foreign_key :monitoring_api_keys, :organizations
  end
end
