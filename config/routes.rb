require "sidekiq/web"
Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  namespace :v1 do
    post "auth/sign_in",         to: "auth#sign_in"
    post "auth/sign_up_client",  to: "auth#sign_up_client"
    post "auth/sign_up_provider",to: "auth#sign_up_provider"

    resources :providers, only: [:index, :show] do
      get :availability, on: :member
    end
    
    resources :time_slots,        only: [:index]
    resources :external_blocks,   only: [:index, :create, :update, :destroy]
    get  "bookings/me",           to: "bookings#me"
    post "bookings/hold",         to: "bookings#hold"
    post "bookings/:id/confirm",  to: "bookings#confirm"
    post "bookings/:id/cancel",   to: "bookings#cancel"
    post "bookings/:id/accept",   to: "bookings#accept"
    post "bookings/:id/decline",  to: "bookings#decline"
    resources :calendar_webhooks, only: [:create]
  end
end