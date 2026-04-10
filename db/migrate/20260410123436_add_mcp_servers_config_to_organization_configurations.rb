class AddMcpServersConfigToOrganizationConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_column :organization_configurations, :mcp_servers_config, :jsonb, default: {}, null: false
  end
end
