class NotifyClientJob < ApplicationJob
  queue_as :default

  def perform(booking_id, type)
    # TODO: Implement
  end
end