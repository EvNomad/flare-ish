require 'ostruct'

module Bookings
  class AcceptService
    include Callable
    
    def initialize(booking, provider)
      @booking = booking
      @provider = provider
      @redis = REDIS
    end
    
    def call
      ActiveRecord::Base.transaction do
        @booking.reload.lock!
        
        return failure('Booking no longer available') unless @booking.status == 'submitted'
        
        @booking.update!(status: 'accepted')
        
        # Update slot state
        provider_time_slot = @booking.provider_time_slot
        provider_time_slot.update!(state: 'booked', source: 'booking')
        
        # Invalidate caches
        invalidate_caches
        
        # Notify client (async)
        NotifyClientJob.perform_later(@booking.id, 'accepted')
        
        success(@booking)
      end
    rescue StandardError => e
      failure(e.message)
    end
    
    private
    
    def invalidate_caches
      provider_time_slot = @booking.provider_time_slot
      @redis.del("provider:#{provider_time_slot.provider_id}:availability:#{provider_time_slot.time_slot.local_date}")
      @redis.del("time_slot:#{provider_time_slot.time_slot_id}:open_providers")
    end
    
    def success(booking)
      OpenStruct.new(success?: true, booking: booking)
    end
    
    def failure(message)
      OpenStruct.new(success?: false, error: message)
    end
  end
end 