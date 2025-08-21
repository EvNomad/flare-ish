require "sidekiq/web"
Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  namespace :v1 do
    resources :providers, only: [:index, :show] do
      get :availability, on: :member
    end
    resources :time_slots, only: [:index]
    resources :external_blocks, only: [:index, :create, :update, :destroy]
    post "bookings/hold", to: "bookings#hold"
    post "bookings/:id/confirm", to: "bookings#confirm"
    post "bookings/:id/accept",  to: "bookings#accept"
    post "bookings/:id/decline", to: "bookings#decline"
    resources :calendar_webhooks, only: [:create]
  end
end