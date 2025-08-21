class Client < ApplicationRecord
  has_many :bookings, dependent: :destroy
  validates :name, :email, :phone, presence: true
  validates :email, uniqueness: true
end
