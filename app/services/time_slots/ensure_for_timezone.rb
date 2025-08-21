module TimeSlots
  class EnsureForTimezone
    HORIZON_DAYS = 60
    CACHE_TTL    = 12.hours

    def self.call(tz:, start_date: Date.current.beginning_of_month, days: HORIZON_DAYS)
      new(tz, start_date, days).call
    end

    def initialize(tz, start_date, days)
      @tz         = tz
      @start_date = start_date
      @days       = days
      @redis      = REDIS
    end

    def call
      debugger
      # 1) Check cache
      cache_key = "tz:#{@tz}"
      blob = @redis.get(cache_key)
      return JSON.parse(blob, symbolize_names: true) if blob.present?

      # 2) Check DB
      db_list = fetch_from_db
      if db_list.size >= expected_min_count # heuristically "we have horizon"
        write_cache(db_list)
        return db_list
      end

      # 3) Generate missing, upsert, then fill cache & return
      generated = generate_horizon
      upsert!(generated)
      list = fetch_from_db # re-read for uniform shape (or combine generated)
      write_cache(list)
      list
    end

    private

    def expected_min_count
      # Worst case: DST fall back adds 1 hour that day (so 24 or 25 hours/day).
      # Use a conservative threshold: at least 23 slots/day * days.
      (@days * 23)
    end

    def fetch_from_db
      range = (@start_date..(@start_date + @days))
      TimeSlot.where(tz: @tz, local_date: range).order(:local_date, :local_time)
    end

    def write_cache(list)
      @redis.set("tz:#{@tz}", list.to_json, ex: CACHE_TTL.to_i) if list.present?
    end

    def generate_horizon
      zone = ActiveSupport::TimeZone[@tz] or raise ArgumentError, "Invalid TZ #{@tz}"
      tzinfo = zone.tzinfo

      out = []
      (@start_date..(@start_date + @days)).each do |date|
        24.times do |hour|
          # Create local time in the target timezone
          local_time = zone.local(date.year, date.month, date.day, hour, 0, 0)
          
          # Check for DST transitions at this local time
          periods = tzinfo.periods_for_local(local_time)
          
          case periods.length
          when 0
            # Gap: this local time doesn't exist (spring forward)
            next
          when 1
            # Normal case: one period
            start_utc = local_time.utc
            out << build_slot(@tz, date, hour, 0, start_utc)
          when 2
            # Overlap: this local time appears twice (fall back)
            periods.each_with_index do |period, fold|
              # Use the period's UTC offset for accurate conversion
              start_utc = local_time - period.utc_total_offset.seconds
              out << build_slot(@tz, date, hour, fold, start_utc)
            end
          else
            # Extremely rare: handle conservatively
            periods.each_with_index do |period, fold|
              start_utc = local_time - period.utc_total_offset.seconds
              out << build_slot(@tz, date, hour, fold, start_utc)
            end
          end
        end
      end
      out
    end

    # Deterministic string primary key:
    # "ts:<TZ>:<YYYY-MM-DD>:<HH:MM>:fold<FOLD>"
    def slot_id(tz, date, hhmm, fold)
      "ts:#{tz}:#{date}:#{hhmm}:fold#{fold}"
    end

    def build_slot(tz, local_date, hour, fold, start_utc)
      local_time = format("%02d:00", hour)
      {
        id:        slot_id(tz, local_date, local_time, fold),
        tz:        tz,
        local_date: local_date,
        local_time: local_time,
        fold:      fold,
        start_utc: start_utc,
        end_utc:   start_utc + 1.hour
      }
    end

    def upsert!(rows)
      return if rows.empty?
      now = Time.current
      payload = rows.map do |h|
        {
          id:         h[:id],
          tz:         h[:tz],
          local_date: h[:local_date],
          local_time: h[:local_time],
          fold:       h[:fold],
          start_utc:  h[:start_utc],
          end_utc:    h[:end_utc],
          created_at: now,
          updated_at: now
        }
      end
      TimeSlot.insert_all(payload, unique_by: "index_time_slots_identity")
    end
  end
end