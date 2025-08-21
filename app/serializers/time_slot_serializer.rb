class TimeSlotSerializer
  def initialize(record) = @r = record
  def as_json(*)
    r = to_hash(@r)
    {
      id:         r[:id],
      tz:         r[:tz],
      local_date: r[:local_date],
      local_time: r[:local_time].to_time.strftime("%H:%M"),
      fold:       r[:fold],
      start_utc:  r[:start_utc].to_datetime.iso8601,
      end_utc:    r[:end_utc].to_datetime.iso8601
    }
  end

  def to_hash(obj)
    if obj.is_a?(Hash)
      obj.symbolize_keys
    elsif obj.respond_to?(:attributes)
      obj.attributes.symbolize_keys
    else
      raise "Unknown object type: #{obj.class}"
    end
  end
end
