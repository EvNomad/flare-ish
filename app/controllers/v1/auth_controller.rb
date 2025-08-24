module V1
  class AuthController < ApplicationController
    include Authenticable

    # POST /v1/auth/sign_in
    def sign_in
      acc = Account.find_by(email: params[:email].to_s.downcase)
      return render json: { error: "invalid credentials" }, status: :unauthorized unless acc&.authenticate(params[:password])

      token = JsonWebToken.encode({ sub: acc.id, role: acc.role, client_id: acc.client_id, provider_id: acc.provider_id })
      render json: { access_token: token, token_type: "Bearer", account: { id: acc.id, role: acc.role, client_id: acc.client_id, provider_id: acc.provider_id } }
    end

    # POST /v1/auth/sign_up_client
    def sign_up_client
      client = Client.create!(name: params[:name], email: params[:email], phone: params[:phone])
      acc = Account.create!(email: params[:email].downcase, password: params[:password], role: :client, client: client)
      token = JsonWebToken.encode({ sub: acc.id, role: "client", client_id: client.id })
      render json: { access_token: token }, status: :created
    end

     # POST /v1/auth/sign_up_provider
    def sign_up_provider
      provider = Provider.create!(name: params[:name], email: params[:email], tz: params[:tz])
      acc = Account.create!(email: params[:email].downcase, password: params[:password], role: :provider, provider: provider)
      token = JsonWebToken.encode({ sub: acc.id, role: "provider", provider_id: provider.id })
      render json: { access_token: token }, status: :created
    end
  end
end