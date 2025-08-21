class WeeklyTemplate < ApplicationRecord
  belongs_to :provider

  validates :dow, :start_local, :end_local, presence: true
  validates :dow, inclusion: { in: 0..6 }
end
