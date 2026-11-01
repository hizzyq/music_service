class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base

  def self.encode(payload, exp = 24.hours.from_now)
    exp = exp[:exp] if exp.is_a?(Hash) && exp.key?(:exp)
    payload_to_encode = payload.dup
    payload_to_encode[:exp] = exp.to_i
    JWT.encode(payload_to_encode, SECRET_KEY, "HS256")
  end

  def self.decode(token)
    return nil if token.blank?

    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: "HS256" })[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    Rails.logger.debug "JWT Decode Error: #{e.message}"
    nil
  end
end