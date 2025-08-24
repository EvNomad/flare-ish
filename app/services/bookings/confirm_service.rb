require 'ostruct'

module Bookings
  class ConfirmService
    include Callable
    
    def initialize(booking, client)
      @booking = booking
      @client = client
      @account = client.account
      @lock = RedisLock.new(@booking.provider_time_slot_id)
    end
    
    def call
      return failure('Not your held slot') unless verify_lock_ownership
      
      ActiveRecord::Base.transaction do
        @booking.reload.lock!
        
        return failure('Hold expired or no longer available') unless @booking.status == 'held'
        
        @booking.update!(status: 'submitted')
        
        @lock.release
        
        NotifyProviderJob.perform_later(@booking.id, 'submitted')
        
        success(@booking)
      end
    rescue StandardError => e
      failure(e.message)
    end
    
    private
    
    def verify_lock_ownership
      @lock.belongs_to?(@account.id)
    end
    
    def success(booking)
      OpenStruct.new(success?: true, booking: booking)
    end
    
    def failure(message)
      OpenStruct.new(success?: false, error: message)
    end
  end
end 