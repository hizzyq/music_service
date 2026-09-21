class AuthenticationController < ApplicationController
  # POST /auth/register
  def register
    user = User.new(user_params)

    if user.save
      token = JsonWebToken.encode(user_id: user.id, role: user.role)
      render json: auth_payload(user, token), status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /auth/login
  def login
    user = User.find_by(email: params[:email]&.downcase&.strip)

    if user&.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id, role: user.role)
      render json: auth_payload(user, token), status: :ok
    else
      render json: { error: "Неверный email или пароль" }, status: :unauthorized
    end
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end

  def auth_payload(user, token)
    {
      token: token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role
      }
    }
  end
end