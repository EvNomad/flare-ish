class ProviderSerializer
  def initialize(record) = @r = to_hash(record)

  def as_json(*)
    {
      id: @r[:id],
      name: @r[:name],
      email: @r[:email],
      tz: @r[:tz],
      service_type: @r[:service_type]
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
end 