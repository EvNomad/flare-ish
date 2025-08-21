# app/services/availability/recompute_day.rb
# Recalculate ProviderTimeSlot states for a provider and one local date.
# Precedence: booked > held > blocked > open
#
# Triggers:
# - WeeklyTimeSlotTemplate edit / override
# - ExternalBlock webhook/poll
# - Booking state change (held/submitted/accepted/cancelled)
# - Nightly reconciliation
# - Provider timezone change

module Availability
  class RecomputeDay
    def self.call(provider_id:, local_date:, tz:)
      new(provider_id, local_date, tz).call
    end

    def initialize(provider_id, local_date, tz)
      @provider_id = provider_id
      @local_date  = local_date
      @tz          = tz
      @redis       = REDIS
    end

    def call      
      time_slots = load_time_slots_for_date
      candidate_ids = get_candidate_slot_ids(time_slots)
      blocked_ids = get_blocked_slot_ids(time_slots)
      booking_ids = get_live_booking_slot_ids(time_slots)
      all_ids = (candidate_ids | blocked_ids | booking_ids)

      return [] if all_ids.empty?

      ensure_provider_time_slots_exist(all_ids)

      changes = calculate_state_changes(all_ids, time_slots, blocked_ids: blocked_ids)

      apply_changes(changes)
      invalidate_caches(all_ids)

      changes
    end

    private

    def load_time_slots_for_date
      TimeSlot
        .where(tz: @tz)
        .where(local_date: @local_date)
        .order(:start_utc)
        .pluck(:id, :local_time, :start_utc, :end_utc)
        .map { |id, local_time, start_utc, end_utc|
          { id: id, local_time: local_time, start_utc: start_utc, end_utc: end_utc }
        }
    end

    def get_candidate_slot_ids(time_slots)
      wday = @local_date.wday
      templates = WeeklyTemplate
                    .where(provider_id: @provider_id, dow: wday)
                    .pluck(:start_local, :end_local)

      return [] if templates.blank?

      time_slots
        .select { |ts| slot_in_templates?(ts[:local_time], templates) }
        .map { |ts| ts[:id] }
    end

    def slot_in_templates?(local_time, templates)
      templates.any? { |start_local, end_local|
        (start_local...end_local).cover?(local_time)
      }
    end

    def ensure_provider_time_slots_exist(candidate_ids)
      existing_ids = ProviderTimeSlot
                       .where(provider_id: @provider_id, time_slot_id: candidate_ids)
                       .pluck(:time_slot_id)
                       .to_set

      missing_ids = candidate_ids.reject { |id| existing_ids.include?(id) }

      return if missing_ids.empty?

      now = Time.current
      rows = missing_ids.map do |id|
        {
          provider_id: @provider_id,
          time_slot_id: id,
          state: 'open',
          source: 'template',
          created_at: now,
          updated_at: now
        }
      end

      ProviderTimeSlot.insert_all(rows, unique_by: %i[provider_id time_slot_id])
    end

    def calculate_state_changes(candidate_ids, time_slots, blocked_ids: nil)
      current_states = get_current_states(candidate_ids)
      blocked_ids ||= get_blocked_slot_ids(time_slots)
      booking_states = get_booking_states(candidate_ids)

      changes = []

      candidate_ids.each do |slot_id|
        final_state = determine_final_state(slot_id, blocked_ids, booking_states)
        current_state = current_states[slot_id] || 'open'

        next if current_state == final_state

        changes << {
          time_slot_id: slot_id,
          from: current_state,
          to: final_state,
          source: source_for_state(final_state)
        }
      end

      changes
    end

    def get_current_states(candidate_ids)
      ProviderTimeSlot
        .where(provider_id: @provider_id, time_slot_id: candidate_ids)
        .pluck(:time_slot_id, :state)
        .to_h
    end

    def get_blocked_slot_ids(time_slots)
      return [] if time_slots.empty?

      # Convert local date to the provider's timezone first, then to UTC
      day_start_local = @local_date.to_time.in_time_zone(@tz).beginning_of_day
      day_end_local = day_start_local + 24.hours
      day_start_utc = day_start_local.utc
      day_end_utc = day_end_local.utc

      # Debug: let's see what we're actually querying
      Rails.logger.debug "Querying external blocks for provider #{@provider_id}"
      Rails.logger.debug "Day boundaries: #{day_start_utc} to #{day_end_utc}"
      Rails.logger.debug "Local date: #{@local_date}, TZ: #{@tz}"

      external_blocks = ExternalBlock
                          .where(provider_id: @provider_id)
                          .where("start_utc < ? AND end_utc > ?", day_end_utc, day_start_utc)

      Rails.logger.debug "Found #{external_blocks.count} external blocks"

      return [] if external_blocks.blank?

      time_slots.select do |ts|
        external_blocks.any? { |eb| time_slots_overlap?(ts, eb) }
      end.map { |ts| ts[:id] }
    end

    def time_slots_overlap?(time_slot, external_block)
      (time_slot[:start_utc] < external_block.end_utc) &&
      (external_block.start_utc < time_slot[:end_utc])
    end

    def get_live_booking_slot_ids(time_slots)      
      ids_for_day = time_slots.map { |ts| ts[:id] }
      return [] if ids_for_day.empty?
      Booking
        .where(provider_id: @provider_id, time_slot_id: ids_for_day)
        .where(status: %w[held submitted accepted])
        .distinct
        .pluck(:time_slot_id)
    end

    def get_booking_states(candidate_ids)
      bookings = Booking
                   .where(provider_id: @provider_id, time_slot_id: candidate_ids)
                   .where(status: %w[held submitted accepted])

      bookings.each_with_object({}) do |booking, states|
        case booking.status
        when 'accepted'
          states[booking.time_slot_id] = 'booked'
        when 'held', 'submitted'
          states[booking.time_slot_id] = 'held' unless states[booking.time_slot_id] == 'booked'
        end
      end
    end

    def determine_final_state(slot_id, blocked_ids, booking_states)
      return 'booked' if booking_states[slot_id] == 'booked'
      return 'held' if booking_states[slot_id] == 'held'
      return 'blocked' if blocked_ids.include?(slot_id)
      'open'
    end

    def source_for_state(state)
      case state
      when 'blocked' then 'external_block'
      when 'booked', 'held' then 'booking'
      else 'template'
      end
    end

    def apply_changes(changes)
      return if changes.empty?

      ActiveRecord::Base.transaction do
        changes.group_by { |change| change[:to] }.each do |target_state, group|
          ids = group.map { |change| change[:time_slot_id] }
          source = source_for_state(target_state)

          ProviderTimeSlot
            .where(provider_id: @provider_id, time_slot_id: ids)
            .update_all(
              state: target_state,
              source: source,
              updated_at: Time.current
            )
        end
      end
    end

    def invalidate_caches(candidate_ids)
      candidate_ids.each do |slot_id|
        @redis.del("time_slot:#{slot_id}:open_providers")
      end

      @redis.del("provider:#{@provider_id}:availability:#{@local_date}")
    end
  end
end 