require "rails_helper"

RSpec.describe PaysHelper, type: :helper do
  describe "#kakin_power" do
    it "金額を、桁区切りつきの課金力で表示すること（1円=1課金力）" do
      expect(helper.kakin_power(10_000)).to eq("10,000課金力")
    end

    it "1,000未満の金額も、そのまま表示すること" do
      expect(helper.kakin_power(500)).to eq("500課金力")
    end
  end
end
