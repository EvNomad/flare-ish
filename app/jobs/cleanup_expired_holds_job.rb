class CleanupExpiredHoldsJob < ApplicationJob
  queue_as :default

  def perform
    expired_holds = Booking
      .joins(:provider_time_slot)
      .where(status: 'held')
      .where('bookings.created_at < ?', 10.minutes.ago)

    expired_holds.each do |booking|
      cleanup_expired_hold(booking)
    end
  end

  private

  def cleanup_expired_hold(booking)
    ActiveRecord::Base.transaction do
      booking.provider_time_slot.update!(state: 'open', source: 'template')
      
      booking.update!(status: 'expired')
      
      lock = RedisLock.new(booking.provider_time_slot_id)
      lock.release if lock.exists?
      
      Rails.logger.info "Cleaned up expired hold: Booking #{booking.id}, ProviderTimeSlot #{booking.provider_time_slot_id}"
    end
  rescue => e
    Rails.logger.error "Failed to cleanup expired hold #{booking.id}: #{e.message}"
  end
end 