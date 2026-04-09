class AddFunctionProvidersAndAssistantChatbotToOrganizationConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_column :organization_configurations, :function_providers_config, :jsonb, default: {}, null: false
    add_column :organization_configurations, :assistant_chatbot_config, :jsonb, default: {}, null: false
  end
end
