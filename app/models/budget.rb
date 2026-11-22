class Budget < ApplicationRecord
  belongs_to :user
  validates :amount, numericality: {
  only_integer: true,
  greater_than: 0,
  less_than_or_equal_to: 1_000_000
}

  # 合計に対する、予算の進捗（%）。小数点以下は切り捨て。超過なら、100を超える
  def progress_percent(total)
    total * 100 / amount
  end

  # 合計が、予算を超えたか（ちょうど同じは、超過ではない）
  def over?(total)
    total > amount
  end

  # 進捗バーの幅（%）。100で止める
  def bar_percent(total)
    [ progress_percent(total), 100 ].min
  end
end
