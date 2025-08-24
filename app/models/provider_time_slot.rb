class ProviderTimeSlot < ApplicationRecord
  belongs_to :provider
  belongs_to :time_slot
  has_many :bookings, dependent: :destroy
  enum :state, { open: "open", held: "held", booked: "booked", blocked: "blocked" }
end
