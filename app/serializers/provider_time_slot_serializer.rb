class ProviderTimeSlotSerializer
  def initialize(record) = @r = to_hash(record)

  def as_json(*)
    {
      id: @r[:id],
      time_slot_id: @r[:time_slot_id],
      state: @r[:state],
      source: @r[:source],
      local_date: @r[:local_date],
      local_time: format_local_time(@r[:local_time]),
      start_utc: iso_time(@r[:start_utc]),
      end_utc: iso_time(@r[:end_utc])
    }
  end

  private

  def to_hash(obj)
    if obj.is_a?(Hash)
      obj.symbolize_keys
    elsif obj.respond_to?(:attributes)
      obj.attributes.symbolize_keys
    else
      raise "Unknown object type: #{obj.class}"
    end
  end

  def format_local_time(value)
    value.respond_to?(:strftime) ? value.strftime("%H:%M") : value
  end

  def iso_time(value)
    value.respond_to?(:to_datetime) ? value.to_datetime.iso8601 : value
  end
end 