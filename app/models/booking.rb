class Booking < ApplicationRecord
  belongs_to :provider
  belongs_to :time_slot
  belongs_to :client

  enum :status, { held: "held", submitted: "submitted", accepted: "accepted", cancelled: "cancelled" }
end
