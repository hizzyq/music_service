class User < ApplicationRecord
  has_secure_password

  # Современный синтаксис enum в Rails:
  # 0 => listener (по умолчанию), 1 => admin
  enum :role, { listener: 0, admin: 1 }, default: :listener

  # Нормализация email перед сохранением
  before_validation { self.email = email.to_s.strip.downcase }

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "некорректный формат почты" }

  validates :role, presence: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
end