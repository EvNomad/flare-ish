require 'ostruct'

module Bookings
  class HoldService
    include Callable

    def initialize(provider_time_slot_id, client)
      @provider_time_slot_id = provider_time_slot_id
      @client = client
      @account = client.account
      @lock = RedisLock.new(provider_time_slot_id)
      @redis = REDIS
    end
    
    def call
      return failure('Slot already locked') unless acquire_lock
      
      ActiveRecord::Base.transaction do
        provider_time_slot = ProviderTimeSlot.find(@provider_time_slot_id)
        provider_time_slot.lock!
        
        return failure('Slot no longer available') unless provider_time_slot.state == 'open'
        
        @booking = create_booking(provider_time_slot)
        update_slot_state(provider_time_slot)
      end
      
      invalidate_caches
      success(@booking)
      
    rescue StandardError => e
      @lock.release
      failure(e.message)
    end
    
    private
    
    def acquire_lock
      lock_metadata = { 
        account_id: @account.id,
        client_id: @client.id
      }
      @lock.acquire(lock_metadata)
    end
    
    def create_booking(provider_time_slot)
      Booking.create!(
        client_id: @client.id,
        provider_time_slot_id: @provider_time_slot_id,
        status: 'held'
      )
    end
    
    def update_slot_state(provider_time_slot)
      provider_time_slot.update!(state: 'held', source: 'booking')
    end
    
    def invalidate_caches
      provider_time_slot = ProviderTimeSlot.find(@provider_time_slot_id)
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