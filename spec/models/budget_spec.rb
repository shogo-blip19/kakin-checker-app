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
end
