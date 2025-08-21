class V1::ProvidersController < ApplicationController
  def index
    @providers = Provider.all
    @providers = @providers.where(service_type: params[:service_type]) if params[:service_type].present?
    
    if params[:time_slot_id].present?
      data = Providers::FetchWithTimeSlot.call(providers: @providers, time_slot_id: params[:time_slot_id])
      render json: data.map { |item| ProviderWithTimeSlotSerializer.new(item).as_json }
    else
      render json: @providers.map { |p| ProviderSerializer.new(p).as_json }
    end
  end

  def show
    @provider = Provider.find(params[:id])
    render json: @provider
  end

  def availability
    provider = Provider.find(params[:id])
    from_date = parse_local_date(params[:from], provider.tz)
    to_date   = parse_local_date(params[:to], provider.tz)

    raise ArgumentError, "from must be <= to" if from_date > to_date

    results = Availability::FetchRange.call(
      provider_id: provider.id,
      tz: provider.tz,
      from_date: from_date,
      to_date: to_date,
      ttl_seconds: 300,
      sync_limit_days: 7
    )

    render json: results
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def provider_params
    params.require(:provider).permit(:name, :tz, :email, :service_type)
  end

  def time_slot_params
    params.require(:time_slot).permit(:id)
  end

  def parse_local_date(value, tz)
    Time.use_zone(tz) do
      t = Time.zone.parse(value.to_s)
      raise ArgumentError, "invalid date: #{value}" unless t
      t.to_date
    end
  end
end