module Availability
  class FetchRange
    def self.call(provider_id:, tz:, from_date:, to_date:, ttl_seconds: 300, sync_limit_days: 7)
      new(provider_id, tz, from_date, to_date, ttl_seconds, sync_limit_days).call
    end

    def initialize(provider_id, tz, from_date, to_date, ttl_seconds, sync_limit_days)
      @provider_id = provider_id
      @tz = tz
      @from_date = from_date
      @to_date = to_date
      @ttl_seconds = ttl_seconds
      @sync_limit_days = sync_limit_days
      @redis = REDIS
    end

    def call
      date_range = (@from_date..@to_date).to_a
      keys = date_range.map { |d| day_key(d) }

      blobs = keys.each_slice(100).flat_map { |slice| @redis.mget(slice) }

      results = []
      missing_dates = []

      blobs.each_with_index do |blob, idx|
        if blob.present?
          results.concat(JSON.parse(blob))
        else
          missing_dates << date_range[idx]
        end
      end

      return results if missing_dates.empty?

      days_map = fetch_provider_days_in_range(@provider_id, missing_dates.min, missing_dates.max)

      empty_days = missing_dates.select { |d| (days_map[d] || []).empty? }
      sync_days, async_days = empty_days.first(@sync_limit_days), empty_days.drop(@sync_limit_days)

      sync_days.each do |d|
        Availability::RecomputeDay.call(provider_id: @provider_id, local_date: d, tz: @tz)
      end

      async_days.each do |d|
        Availability::RecomputeDayJob.perform_later(@provider_id, d, @tz)
      end

      if sync_days.any?        
        refreshed = fetch_provider_days_in_range(@provider_id, sync_days.min, sync_days.max)
        sync_days.each { |d| days_map[d] = refreshed[d] }
      end

      missing_dates.each do |d|
        day = (days_map[d] || [])
        @redis.set(day_key(d), day.to_json, ex: @ttl_seconds)
        results.concat(day)
      end

      results
    end

    private

    def day_key(local_date)
      "provider:#{@provider_id}:availability:#{local_date}"
    end

    def fetch_provider_days_in_range(provider_id, from_date, to_date)
      rows = ProviderTimeSlot
        .joins(:time_slot)
        .where(provider_id: provider_id)
        .where(time_slots: { local_date: from_date..to_date })
        .order("time_slots.start_utc ASC")
        .pluck(
          "time_slots.local_date",
          "provider_time_slots.time_slot_id",
          "provider_time_slots.state",
          "provider_time_slots.source",
          "time_slots.local_time",
          "time_slots.start_utc",
          "time_slots.end_utc"
        )

      grouped = rows.group_by { |local_date, *_| local_date }

      grouped.transform_values do |group|
        group.map do |local_date, time_slot_id, state, source, local_time, start_utc, end_utc|
          ProviderTimeSlotSerializer.new(
            time_slot_id: time_slot_id,
            state: state,
            source: source,
            local_date: local_date,
            local_time: local_time,
            start_utc: start_utc,
            end_utc: end_utc
          ).as_json
        end
      end
    end
  end
end 