class BookingSerializer
  def initialize(record) = @r = record

  def as_json(*)
    {
      id: @r.id,
      status: @r.status,
      time_slot: {
        id: @r.provider_time_slot.id,
        time_slot_id: @r.provider_time_slot.time_slot_id,
        state: @r.provider_time_slot.state,
        source: @r.provider_time_slot.source,
        local_date: @r.provider_time_slot.time_slot.local_date,
        local_start: @r.start_local,
        local_end: @r.end_local
      },
      provider: ProviderSerializer.new(@r.provider).as_json,
      client: {
        id: @r.client.id,
        name: @r.client.name,
        email: @r.client.email,
        phone: @r.client.phone
      }
    }
  end
end