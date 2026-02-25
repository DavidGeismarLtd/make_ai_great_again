class CreateApiConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :api_configurations do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :key_name, null: false
      t.text :encrypted_api_key
      t.boolean :is_active, default: true
      t.datetime :last_validated_at

      t.timestamps
    end

    add_index :api_configurations, [ :organization_id, :provider, :key_name ],
              unique: true, name: "index_api_configs_on_org_provider_name"
  end
end
