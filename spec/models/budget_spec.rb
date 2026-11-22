require 'rails_helper'

RSpec.describe Budget, type: :model do
describe "バリデーションのテスト" do
    it "正しい入力なら有効であること" do
      budget = build(:budget)

      expect(budget).to be_valid
    end

    context "amountのバリデーション" do
      it "amountが空欄の場合は無効であること" do
        budget = build(:budget, amount: nil)

        expect(budget).to be_invalid
        expect(budget.errors[:amount]).to be_present
      end

      it "amountが0以下の場合は無効であること" do
        budget = build(:budget, amount: 0)

        expect(budget).to be_invalid
        expect(budget.errors[:amount]).to be_present
      end

      it "amountが1,000,000を超える場合は無効であること" do
        budget = build(:budget, amount: 1_000_001)

        expect(budget).to be_invalid
        expect(budget.errors[:amount]).to be_present
      end

      it "amountが1以上1,000,000以下の場合は有効であること" do
        budget = build(:budget, amount: 500_000)

        expect(budget).to be_valid
      end

      it "amountが1の場合は有効であること" do
        budget = build(:budget, amount: 1)

        expect(budget).to be_valid
      end

      it "amountが1,000,000の場合は有効であること" do
        budget = build(:budget, amount: 1_000_000)

        expect(budget).to be_valid
      end

      it "amountが整数でない場合は無効であること" do
        budget = build(:budget, amount: 10.5)

        expect(budget).to be_invalid
        expect(budget.errors[:amount]).to be_present
      end
      it "amountがマイナスの場合は無効であること" do
        budget = build(:budget, amount: -100)

        expect(budget).to be_invalid
        expect(budget.errors[:amount]).to be_present
      end
    end

    context "userとの関係" do
      it "userが存在しない場合は無効であること" do
        budget = build(:budget, user: nil)

        expect(budget).to be_invalid
        expect(budget.errors[:user]).to be_present
      end
    end
  end

  describe "進捗の計算" do
    let(:budget) { build(:budget, amount: 50_000) }

    describe "#progress_percent" do
      it "合計が0円なら、0%になること" do
        expect(budget.progress_percent(0)).to eq(0)
      end

      it "予算の60%なら、60になること" do
        expect(budget.progress_percent(30_000)).to eq(60)
      end

      it "予算ちょうどなら、100になること" do
        expect(budget.progress_percent(50_000)).to eq(100)
      end

      it "予算を超えたら、100を超えること" do
        expect(budget.progress_percent(60_000)).to eq(120)
      end

      it "小数点以下は切り捨てること（予算に1円足りなくても、100%にならない）" do
        expect(budget.progress_percent(49_999)).to eq(99)
      end

      it "1円超過でも、100%と表示されること（超過かどうかは、over?で判定する）" do
        expect(budget.progress_percent(50_001)).to eq(100)
      end
    end

  describe "#over?" do
      it "合計が予算より少なければ、超過ではないこと" do
        expect(budget.over?(49_999)).to be(false)
      end

      it "合計が予算とちょうど同じなら、超過ではないこと" do
        expect(budget.over?(50_000)).to be(false)
      end

      it "1円でも予算を超えたら、超過であること" do
        expect(budget.over?(50_001)).to be(true)
      end

      it "合計が0円なら、超過ではないこと" do
        expect(budget.over?(0)).to be(false)
      end
    end

    describe "#bar_percent" do
      it "予算以内なら、割合のままであること" do
        expect(budget.bar_percent(30_000)).to eq(60)
      end

      it "超過しても、100で止まること" do
        expect(budget.bar_percent(150_000)).to eq(100)
      end
    end
  end
end
