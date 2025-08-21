class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :provider, null: false, foreign_key: true
      t.references :time_slot, null: false, type: :string, foreign_key: { to_table: :time_slots }
      t.references :client, null: false, foreign_key: true
      t.string :status,       null: false, default: "held" # held|submitted|accepted|cancelled
      t.datetime :hold_expires_at

      t.timestamps
    end
    add_index :bookings, [:provider_id, :time_slot_id]
    add_index :bookings,
              [:provider_id, :time_slot_id, :status],
              name: "idx_unique_active_booking",
              unique: true,
              where: "status IN ('held','submitted','accepted')"
  end
end
