class Provider < ApplicationRecord
    has_many :provider_time_slots, dependent: :destroy
    has_many :weekly_templates, dependent: :destroy
    has_many :external_blocks, dependent: :destroy
    has_many :bookings, dependent: :destroy

    validates :name, :tz, :email, :service_type, presence: true
    validates :email, uniqueness: true

    enum :service_type, { consultation: 1, review: 2, other: 3 }
end
