class ApplicationController < ActionController::API
  attr_reader :current_user

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header.present?

    decoded = JsonWebToken.decode(token) if token
    @current_user = User.find_by(id: decoded[:user_id]) if decoded

    render json: { error: "Неавторизованный доступ" }, status: :unauthorized unless @current_user
  end
end