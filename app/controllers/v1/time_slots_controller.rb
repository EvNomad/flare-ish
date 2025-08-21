class V1::TimeSlotsController < ApplicationController
  def index
    @time_slots = TimeSlots::EnsureForTimezone.call(tz: params[:tz])
    render json: @time_slots.map { TimeSlotSerializer.new(_1) }
  end
end