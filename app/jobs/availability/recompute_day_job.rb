module Availability
  class RecomputeDayJob < ApplicationJob
    queue_as :default

    def perform(provider_id, local_date, tz)
      Availability::RecomputeDay.call(provider_id: provider_id, local_date: Date.parse(local_date.to_s), tz: tz)
    end
  end
end 