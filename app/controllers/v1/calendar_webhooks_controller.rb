module V1
  class CalendarWebhooksController < ApplicationController
    def create
      result = Calendar::IngestEvent.call(payload: params)
      render json: { ok: true, result: result }
    rescue ActiveRecord::RecordNotFound => e
      render json: { ok: false, error: e.message }, status: :not_found
    rescue StandardError => e
      render json: { ok: false, error: e.message }, status: :bad_request
    end
  end
end 