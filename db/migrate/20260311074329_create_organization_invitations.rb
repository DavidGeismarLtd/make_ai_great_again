class CreateOrganizationInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :email, null: false
      t.string :role, null: false
      t.string :token, null: false
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.datetime :expires_at, null: false
      t.datetime :accepted_at

      t.timestamps
    end

    add_index :organization_invitations, :token, unique: true
    add_index :organization_invitations, [:organization_id, :email], unique: true, where: "accepted_at IS NULL"
  end
end
