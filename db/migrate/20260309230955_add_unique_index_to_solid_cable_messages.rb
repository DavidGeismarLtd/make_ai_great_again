class AddUniqueIndexToSolidCableMessages < ActiveRecord::Migration[8.1]
  def change
    # Add explicit unique index on id for solid_cable_messages table
    # This is required for ActiveRecord 8.x's insert_all method used by SolidCable
    # Without this, broadcasting Turbo Streams raises "No unique index found for id"

    # Only add if the table exists (it's created by solid_cable gem)
    if table_exists?(:solid_cable_messages)
      add_index :solid_cable_messages, :id, unique: true, if_not_exists: true
    end
  end
end
