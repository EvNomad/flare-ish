class Provider < ApplicationRecord
    has_many :provider_time_slots, dependent: :destroy
    has_many :weekly_templates, dependent: :destroy
    has_many :external_blocks, dependent: :destroy
    has_many :bookings, through: :provider_time_slots, source: :bookings, dependent: :destroy

    validates :name, :tz, :email, :service_type, presence: true
    validates :email, uniqueness: true

    enum :service_type, { consultation: 1, review: 2, other: 3 }

    after_create :create_weekly_templates

    private

    def create_weekly_templates
        (1..5).each do |dow|
            start_str, end_str = case dow
            when 1 then ["10:00", "16:00"]
            when 5 then ["10:00", "14:00"]
            else        ["10:00", "17:00"]
            end
            
            weekly_templates.create!(
            dow: dow,
            start_local: start_str,
            end_local: end_str
            )
        end
    end
end
