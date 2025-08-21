class ProviderWithTimeSlotSerializer
  def initialize(record) = @r = to_hash(record)

  def as_json(*)
    provider_data = ProviderSerializer.new(@r[:provider]).as_json
    
    if @r[:provider_time_slot]
      time_slot_data = ProviderTimeSlotSerializer.new(@r[:provider_time_slot]).as_json
      provider_data.merge(time_slot: time_slot_data)
    else
      provider_data
    end
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
end 