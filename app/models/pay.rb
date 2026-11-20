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

  scope :in_month, ->(date) { where(paid_at: date.all_month) }
  scope :recent_first, -> { order(paid_at: :desc, id: :desc) }



  private

  def paid_at_not_in_future
    return if paid_at.nil?

    errors.add(:paid_at, :future) if paid_at > Date.current
  end

  def preset_title_belongs_to_user
    return if user.nil? || preset_title.nil?

    errors.add(:preset_title, :invalid) if preset_title.user_id != user_id
  end

  # 記録がある月（各月の1日）を、重複なく、新しい順に返す
  def self.record_months
    distinct.pluck(:paid_at).map(&:beginning_of_month).uniq.sort.reverse
  end
end
