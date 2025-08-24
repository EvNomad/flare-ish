module V1
  class BookingsController < ApplicationController
    before_action :require_client!, only: [:hold, :confirm, :cancel]
    before_action :require_provider!, only: [:accept, :decline]
    before_action :set_booking, only: [:confirm, :cancel, :accept, :decline]

    # GET /v1/bookings/me
    def me
      render json: current_account.bookings.map { BookingSerializer.new(_1).as_json }
    end

    # POST /v1/bookings/hold
    def hold
      result = Bookings::HoldService.call(params[:provider_time_slot_id], current_client)
      
      if result.success?
        render json: { 
          id: result.booking.id, 
          status: 'held',
          message: 'Slot held successfully'
        }, status: :created
      else
        render json: { error: result.error }, status: :conflict
      end
    end
    
    # POST /v1/bookings/:id/confirm
    def confirm
      result = Bookings::ConfirmService.call(@booking, current_client)
      
      if result.success?
        render json: { 
          id: @booking.id, 
          status: 'submitted',
          message: 'Hold confirmed successfully'
        }
      else
        render json: { error: result.error }, status: :conflict
      end
    end
    
    # POST /v1/bookings/:id/cancel
    def cancel
      result = Bookings::CancelService.call(@booking, current_client)
      
      if result.success?
        render json: { 
          id: @booking.id, 
          status: 'cancelled',
          message: 'Booking cancelled successfully'
        }
      else
        render json: { error: result.error }, status: :conflict
      end
    end
    
    # POST /v1/bookings/:id/accept
    def accept
      result = Bookings::AcceptService.call(@booking, current_provider)
      
      if result.success?
        render json: { 
          id: @booking.id, 
          status: 'accepted',
          message: 'Booking accepted successfully'
        }
      else
        render json: { error: result.error }, status: :conflict
      end
    end
    
    # POST /v1/bookings/:id/decline
    def decline
      result = Bookings::DeclineService.call(@booking, current_provider)
      
      if result.success?
        render json: { 
          id: @booking.id, 
          status: 'declined',
          message: 'Booking declined successfully'
        }
      else
        render json: { error: result.error }, status: :conflict
      end
    end
    
    private
    
    def set_booking
      case action_name
      when 'confirm', 'cancel'
        @booking = current_client.bookings.find(params[:id])
      when 'accept', 'decline'
        @booking = current_provider.bookings.find(params[:id])
      end
    end
  end
end 