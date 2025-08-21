class AddUniqueIndexToExternalBlocksOnExternalEventId < ActiveRecord::Migration[8.0]
  def change
    add_index :external_blocks, [:provider_id, :external_event_id], unique: true, where: "external_event_id IS NOT NULL"
  end
end 