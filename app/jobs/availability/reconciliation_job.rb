module Availability
  class ReconciliationJob < ApplicationJob
    queue_as :default

    def perform(start_date: nil, end_date: nil, provider_ids: nil)
      @start_date = start_date || Date.current.beginning_of_month
      @end_date = end_date || Date.current.end_of_month + 1.month
      @provider_ids = provider_ids

      providers_to_process = select_providers
      
      Rails.logger.info "Starting availability reconciliation for #{providers_to_process.count} providers from #{@start_date} to #{@end_date}"
      
      providers_to_process.find_each do |provider|
        reconcile_provider(provider)
      end
      
      Rails.logger.info "Availability reconciliation completed"
    end

    private

    def select_providers
      scope = Provider.all
      scope = scope.where(id: @provider_ids) if @provider_ids.present?
      scope
    end

    def reconcile_provider(provider)
      Rails.logger.info "Reconciling provider #{provider.id} (#{provider.name})"
      
      (@start_date..@end_date).each do |local_date|
        begin
          Availability::RecomputeDay.call(
            provider_id: provider.id,
            local_date: local_date,
            tz: provider.tz
          )
        rescue => e
          Rails.logger.error "Failed to reconcile provider #{provider.id} for date #{local_date}: #{e.message}"
          # Continue with other dates rather than failing the entire job
        end
      end
    end
  end
end 