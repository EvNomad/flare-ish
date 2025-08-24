module JsonWebToken
    module_function

  def secret = ENV.fetch("JWT_SECRET")

  def encode(payload, exp: default_exp)
    payload = payload.merge(exp: exp.to_i, iat: Time.now.to_i, jti: SecureRandom.uuid)
    JWT.encode(payload, secret, "HS256")
  end

  def decode(token)
    body, = JWT.decode(token, secret, true, { algorithm: "HS256" })
    body.with_indifferent_access
  rescue JWT::DecodeError => e
    raise UnauthorizedError, e.message
  end

  def default_exp
    Integer(ENV.fetch("JWT_ACCESS_TTL", 12.hours.from_now))
  end

  class UnauthorizedError < StandardError; end
end