class User < ApplicationRecord
  authenticates_with_sorcery!
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  with_options if: -> { new_record? || changes[:crypted_password] } do
    validates :password, presence: true, length: { minimum: 8 }, confirmation: true
    validates :password_confirmation, presence: true
  end
  has_many :preset_titles, dependent: :destroy
  validates :preset_titles, length: { is: 3 }, on: :create
  has_one :budget, dependent: :destroy
end
