class Booking < ApplicationRecord
  belongs_to :provider_time_slot
  belongs_to :client

  enum :status, { held: "held", submitted: "submitted", accepted: "accepted", cancelled: "cancelled", declined: "declined", expired: "expired" }

  delegate :provider, :time_slot, to: :provider_time_slot

  def start_local
    time_slot.start_utc.in_time_zone(provider.tz).strftime("%H:%M")
  end

  def end_local
    time_slot.end_utc.in_time_zone(provider.tz).strftime("%H:%M")
  end
end
