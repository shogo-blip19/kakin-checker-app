class User < ApplicationRecord
  authenticates_with_sorcery!
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  with_options if: -> { new_record? || changes[:crypted_password] } do
    validates :password, presence: true, length: { minimum: 8 }, confirmation: true
    validates :password_confirmation, presence: true
  end
end
