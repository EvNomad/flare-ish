module Providers
  class FetchWithTimeSlot
    def self.call(providers:, time_slot_id:)
      new(providers, time_slot_id).call
    end

    def initialize(providers, time_slot_id)
      @providers = providers
      @time_slot_id = time_slot_id
    end

    def call      
      filtered_providers = filter_providers_by_time_slot
      build_provider_time_slot_data(filtered_providers)
    end

    private

    def filter_providers_by_time_slot
      cache_key = "time_slot:#{@time_slot_id}:open_providers"
      open_provider_ids = REDIS.smembers(cache_key)
      
      if open_provider_ids.any?
        @providers.where(id: open_provider_ids)
      else
        # Fallback to DB if cache miss
        @providers.joins(provider_time_slots: :time_slot)
                 .where(provider_time_slots: { state: "open" }, time_slots: { id: @time_slot_id })
      end
    end

    def build_provider_time_slot_data(providers)
      providers.map do |provider|
        provider_time_slot_data = ProviderTimeSlot
          .joins(:time_slot)
          .where(provider_id: provider.id, time_slot_id: @time_slot_id)
          .pluck(
            "provider_time_slots.id",
            "provider_time_slots.time_slot_id",
            "provider_time_slots.state",
            "provider_time_slots.source",
            "time_slots.local_date",
            "time_slots.local_time",
            "time_slots.start_utc",
            "time_slots.end_utc"
          )
          .first

        if provider_time_slot_data
          id, time_slot_id, state, source, local_date, local_time, start_utc, end_utc = provider_time_slot_data
          {
            provider: provider,
            provider_time_slot: {
              id: id,
              time_slot_id: time_slot_id,
              state: state,
              source: source,
              local_date: local_date,
              local_time: local_time,
              start_utc: start_utc,
              end_utc: end_utc
            }
          }
        else
          {
            provider: provider,
            provider_time_slot: nil
          }
        end
      end
    end
  end
end 