class PresetTitle < ApplicationRecord
  belongs_to :user
  validates :game_title, presence: true, length: { maximum: 20 }

  has_many :pays
end
