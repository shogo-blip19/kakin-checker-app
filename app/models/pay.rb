class Pay < ApplicationRecord
  belongs_to :user
  belongs_to :preset_title

  validates :paid_at, presence: true
  validates :amount, presence: true, numericality: {
    only_integer: true,
    greater_than: 0,
    less_than_or_equal_to: 1_000_000
  }
  validate :paid_at_not_in_future
  validate :preset_title_belongs_to_user

  private

  def paid_at_not_in_future
    return if paid_at.nil?

    errors.add(:paid_at, :future) if paid_at > Date.current
  end

  def preset_title_belongs_to_user
    return if user.nil? || preset_title.nil?

    errors.add(:preset_title, :invalid) if preset_title.user_id != user_id
  end
end
