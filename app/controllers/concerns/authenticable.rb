module Authenticable
  extend ActiveSupport::Concern

  included do
    rescue_from JsonWebToken::UnauthorizedError, with: :unauthorized!
  end

  def current_account
    return @current_account if defined?(@current_account)
    auth = request.authorization
    raise JsonWebToken::UnauthorizedError, "missing token" unless auth&.start_with?("Bearer ")
    token = auth.split(" ", 2).last
    claims = JsonWebToken.decode(token)

    @current_account = Account.find_by(id: claims["sub"])
    raise JsonWebToken::UnauthorizedError, "account not found" unless @current_account

    # optional global invalidation (password reset):
    if @current_account.jti_valid_after && claims["iat"] < @current_account.jti_valid_after.to_i
      raise JsonWebToken::UnauthorizedError, "token revoked"
    end

    @current_account
  end

  def authenticate_account!  = current_account
  def require_client!        = (authenticate_account!; head(:forbidden) unless current_account.client?)
  def require_provider!      = (authenticate_account!; head(:forbidden) unless current_account.provider?)

  def current_client         = current_account&.client
  def current_provider       = current_account&.provider

  private

  def unauthorized!(ex = nil)
    render json: { error: "unauthorized", detail: ex&.message }, status: :unauthorized
  end
end
  