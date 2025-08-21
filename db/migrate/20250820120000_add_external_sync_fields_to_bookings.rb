class AddExternalSyncFieldsToBookings < ActiveRecord::Migration[8.0]
  def change
    add_column :bookings, :external_event_id, :string
    add_column :bookings, :external_calendar_source, :string
    add_column :bookings, :external_calendar_status, :string

    add_index :bookings, [:provider_id, :external_event_id], unique: true, where: "external_event_id IS NOT NULL"
  end
end 