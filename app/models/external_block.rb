class ExternalBlock < ApplicationRecord
  belongs_to :provider
  validates :start_utc, :end_utc, presence: true
end
