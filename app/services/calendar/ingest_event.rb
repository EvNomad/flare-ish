module Calendar
  class IngestEvent
    # Expected payload keys (symbolized or strings):
    # - provider_id: Integer
    # - event_id: String (external event id)
    # - status: String (e.g., "confirmed", "cancelled", "tentative")
    # - kind: String ("booking" or "busy"), optional hint
    # - source: String (e.g., "google", "apple"), optional
    # - start_utc: Time/ISO8601 string
    # - end_utc: Time/ISO8601 string
    # - deleted: Boolean (explicit deletion)
    def self.call(payload:)
      new(payload).call
    end

    def initialize(payload)
      @payload = payload.is_a?(ActionController::Parameters) ? payload.to_unsafe_h : payload
      @payload = deep_symbolize(@payload)
    end

    def call
      debugger
      provider = Provider.find(@payload[:provider_id])
      event_id = @payload[:event_id].presence
      status   = (@payload[:status] || "").to_s.downcase
      kind     = (@payload[:kind] || "").to_s.downcase
      deleted  = ActiveModel::Type::Boolean.new.cast(@payload[:deleted])
      start_utc = parse_time_utc(@payload[:start_utc])
      end_utc   = parse_time_utc(@payload[:end_utc])

      if event_id && (booking = Booking.find_by(provider_id: provider.id, external_event_id: event_id))
        process_booking_update!(booking, status, start_utc, end_utc)
        recompute_span_for!(provider, start_utc, end_utc)
        return { processed: :booking, booking_id: booking.id }
      end

      # Fallback: treat as busy block (non-appointment)
      block = upsert_external_block!(provider, event_id, status, start_utc, end_utc, deleted)
      recompute_span_for!(provider, start_utc, end_utc)
      { processed: :external_block, external_block_id: block&.id }
    end

    private

    def process_booking_update!(booking, external_status, start_utc, end_utc)
      desired_status = map_external_status(external_status)

      # Optionally handle reschedules when start time moved
      if start_utc && booking.time_slot_id
        maybe_move_booking_time_slot!(booking, start_utc)
      end

      if desired_status && booking.status != desired_status
        booking.update!(status: desired_status, external_calendar_status: external_status)
      elsif external_status.present? && booking.external_calendar_status != external_status
        booking.update!(external_calendar_status: external_status)
      end
    end

    def maybe_move_booking_time_slot!(booking, new_start_utc)
      provider = Provider.find(booking.provider_id)
      new_slot = TimeSlot.where(tz: provider.tz, start_utc: new_start_utc).limit(1).first
      return unless new_slot

      # Ensure the destination slot is not blocked/held/booked
      pts_state = ProviderTimeSlot
                    .where(provider_id: provider.id, time_slot_id: new_slot.id)
                    .pluck(:state)
                    .first
      return if %w[blocked held booked].include?(pts_state)

      booking.update!(time_slot_id: new_slot.id)
    end

    def upsert_external_block!(provider, event_id, status, start_utc, end_utc, deleted)
      if deleted || %w[cancelled canceled].include?(status)
        # Remove existing block if any
        if event_id
          if (blk = ExternalBlock.find_by(provider_id: provider.id, external_event_id: event_id))
            blk.destroy!
          end
        else
          if start_utc && end_utc
            if (blk = ExternalBlock.find_by(provider_id: provider.id, start_utc: start_utc, end_utc: end_utc))
              blk.destroy!
            end
          end
        end
        return nil
      end

      attrs = {
        provider_id: provider.id,
        source: "calendar",
        start_utc: start_utc,
        end_utc: end_utc
      }
      attrs[:external_event_id] = event_id if event_id

      record = if event_id
        ExternalBlock.find_or_initialize_by(provider_id: provider.id, external_event_id: event_id)
      else
        ExternalBlock.find_or_initialize_by(provider_id: provider.id, start_utc: start_utc, end_utc: end_utc)
      end

      record.assign_attributes(attrs)
      record.save!
      record
    end

    def recompute_span_for!(provider, start_utc, end_utc)
      return unless start_utc && end_utc
      tz = provider.tz
      start_date = start_utc.in_time_zone(tz).to_date
      end_date   = (end_utc - 1.second).in_time_zone(tz).to_date
      (start_date..end_date).each do |local_date|
        Availability::RecomputeDay.call(provider_id: provider.id, local_date: local_date, tz: tz)
      end
    end

    def map_external_status(external_status)
      case external_status.to_s.downcase
      when "confirmed", "accepted", "busy", "committed"
        "accepted"
      when "tentative", "needs_action", "pending"
        "submitted"
      when "cancelled", "canceled", "declined"
        "cancelled"
      else
        nil
      end
    end

    def parse_time_utc(value)
      return nil if value.blank?
      t = value.is_a?(Time) ? value : Time.parse(value.to_s)
      t.utc
    rescue ArgumentError
      nil
    end

    def deep_symbolize(obj)
      case obj
      when Hash
        obj.each_with_object({}) { |(k, v), h| h[k.to_sym] = deep_symbolize(v) }
      when Array
        obj.map { |e| deep_symbolize(e) }
      else
        obj
      end
    end
  end
end 