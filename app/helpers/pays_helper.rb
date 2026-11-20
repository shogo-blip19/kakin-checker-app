module PaysHelper
  # 1円 = 1課金力（READMEの仕様）。単位の変換は、ここに集約する
  def kakin_power(amount)
    t("pays.power", amount: number_with_delimiter(amount))
  end
end
