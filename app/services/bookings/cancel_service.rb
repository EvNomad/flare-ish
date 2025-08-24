require 'ostruct'

module Bookings
  class CancelService
    include Callable

    def initialize(booking, client)
      @booking = booking
      @client = client
      @redis = REDIS
    end
    
    def call
      ActiveRecord::Base.transaction do
        @booking.reload.lock!
        
        return failure('Booking cannot be cancelled') unless cancellable?
        
        @booking.update!(status: 'cancelled')
        
        provider_time_slot = @booking.provider_time_slot
        provider_time_slot.update!(state: 'open', source: 'template')
        
        invalidate_caches
        
        NotifyProviderJob.perform_later(@booking.id, 'cancelled')
        
        success(@booking)
      end
    rescue StandardError => e
      failure(e.message)
    end
    
    private
    
    def cancellable?
      %w[held submitted accepted].include?(@booking.status)
    end
    
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