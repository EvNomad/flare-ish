class ProviderTimeSlot < ApplicationRecord
  belongs_to :provider
  belongs_to :time_slot
  enum :state, { open: "open", held: "held", booked: "booked", blocked: "blocked" }
end
