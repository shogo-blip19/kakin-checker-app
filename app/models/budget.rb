class Budget < ApplicationRecord
  belongs_to :user
  validates :amount, numericality: {
  only_integer: true,
  greater_than: 0,
  less_than_or_equal_to: 1_000_000
}
end
