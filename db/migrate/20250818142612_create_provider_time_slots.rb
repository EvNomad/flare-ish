class CreateProviderTimeSlots < ActiveRecord::Migration[8.0]
  def change
    create_table :provider_time_slots do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :time_slot, null: false, type: :string, foreign_key: { to_table: :time_slots }
      t.string :state, null: false, default: "open"   # open|held|booked|blocked
      t.string :source, null: false, default: "template" # template|external_block|admin

      t.timestamps
    end
    add_index :provider_time_slots, [:provider_id, :time_slot_id], unique: true
    add_index :provider_time_slots, [:provider_id, :state]
  end
end
