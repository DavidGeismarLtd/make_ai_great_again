class CreateOrganizationConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_configurations do |t|
      t.references :organization, null: false, foreign_key: true, index: { unique: true }
      t.jsonb :contexts_config, default: {}, null: false
      t.jsonb :features_config, default: {}, null: false

      t.timestamps
    end
  end
end
