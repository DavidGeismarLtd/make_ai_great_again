class AddUniqueIndexToPromptTrackerDatasets < ActiveRecord::Migration[8.1]
  def change
    # Add unique index for acts_as_tenant uniqueness validation
    # This supports the validates :name, uniqueness: { scope: [:testable_type, :testable_id] }
    # validation in the Dataset model when combined with acts_as_tenant
    add_index :prompt_tracker_datasets,
              [ :organization_id, :name, :testable_type, :testable_id ],
              unique: true,
              name: "index_datasets_on_org_name_testable"
  end
end
