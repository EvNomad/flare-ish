class UpdateBookingsTableForProviderTimeSlots < ActiveRecord::Migration[8.0]
  def change
    # Remove old columns
    remove_column :bookings, :time_slot_id
    remove_column :bookings, :provider_id
    
    # Add reference to provider_time_slots table
    add_reference :bookings, :provider_time_slot, null: false, foreign_key: true, index: true
  end
end 