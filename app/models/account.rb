class Account < ApplicationRecord
  has_secure_password

  enum :role, { client: 0, provider: 1, admin: 2 }
  belongs_to :client,   optional: true
  belongs_to :provider, optional: true

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validate  :profile_presence

  def profile_presence
    errors.add(:base, "Attach client or provider") if client.nil? && provider.nil? && !admin?
  end

  def bookings
    if client?
      client.bookings
    elsif provider?
      provider.bookings
    end
  end
end