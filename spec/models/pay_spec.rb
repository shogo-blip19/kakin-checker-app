require "rails_helper"

RSpec.describe Pay, type: :model do
  describe "バリデーションのテスト" do
    it "正しい入力なら有効であること" do
      pay = build(:pay)

      expect(pay).to be_valid
    end

    context "amountのバリデーション" do
      it "amountが空欄の場合は無効であること" do
        pay = build(:pay, amount: nil)

        expect(pay).to be_invalid
        expect(pay.errors[:amount]).to be_present
      end

      it "amountが0の場合は無効であること" do
        pay = build(:pay, amount: 0)

        expect(pay).to be_invalid
        expect(pay.errors[:amount]).to be_present
      end

      it "amountがマイナスの場合は無効であること" do
        pay = build(:pay, amount: -1)

        expect(pay).to be_invalid
        expect(pay.errors[:amount]).to be_present
      end

      it "amountが小数の場合は無効であること" do
        pay = build(:pay, amount: "1000.5")

        expect(pay).to be_invalid
        expect(pay.errors[:amount]).to be_present
      end

      it "amountが文字列の場合は無効であること" do
        pay = build(:pay, amount: "abc")

        expect(pay).to be_invalid
        expect(pay.errors[:amount]).to be_present
      end

      it "amountが1の場合は有効であること" do
        pay = build(:pay, amount: 1)

        expect(pay).to be_valid
      end

      it "amountが1,000,000の場合は有効であること" do
        pay = build(:pay, amount: 1_000_000)

        expect(pay).to be_valid
      end

      it "amountが1,000,001の場合は無効であること" do
        pay = build(:pay, amount: 1_000_001)

        expect(pay).to be_invalid
        expect(pay.errors[:amount]).to be_present
      end
    end

    context "paid_atのバリデーション" do
      it "paid_atが空欄の場合は無効であること" do
        pay = build(:pay, paid_at: nil)

        expect(pay).to be_invalid
        expect(pay.errors[:paid_at]).to be_present
      end

      it "paid_atが今日の場合は有効であること" do
        pay = build(:pay, paid_at: Date.current)

        expect(pay).to be_valid
      end

      it "paid_atが過去の日付の場合は有効であること" do
        pay = build(:pay, paid_at: Date.current - 1.year)

        expect(pay).to be_valid
      end

      it "paid_atが明日の場合は無効であること" do
        pay = build(:pay, paid_at: Date.current + 1.day)

        expect(pay).to be_invalid
        expect(pay.errors[:paid_at]).to be_present
      end

      it "paid_atが日付として解釈できない文字列の場合は無効であること" do
        pay = build(:pay, paid_at: "abc")

        expect(pay).to be_invalid
        expect(pay.errors[:paid_at]).to be_present
      end
    end

    context "userのバリデーション" do
      it "userがない場合は無効であること" do
        pay = build(:pay, user: nil, preset_title: nil)

        expect(pay).to be_invalid
        expect(pay.errors[:user]).to be_present
      end
    end

    context "preset_titleのバリデーション" do
      it "preset_titleがない場合は無効であること" do
        pay = build(:pay, preset_title: nil)

        expect(pay).to be_invalid
        expect(pay.errors[:preset_title]).to be_present
      end

      it "自分のpreset_titleを指定した場合は有効であること" do
        user = create(:user)
        pay = build(:pay, user: user, preset_title: user.preset_titles.second)

        expect(pay).to be_valid
      end

      it "他のユーザーのpreset_titleを指定した場合は無効であること" do
        user = create(:user)
        other_user = create(:user)
        pay = build(:pay, user: user, preset_title: other_user.preset_titles.first)

        expect(pay).to be_invalid
        expect(pay.errors[:preset_title]).to be_present
      end
    end
  end

  describe "DBの制約" do
    it "preset_title_idがnullのレコードは保存できないこと" do
      pay = build(:pay)
      pay.preset_title = nil

      expect { pay.save!(validate: false) }.to raise_error(ActiveRecord::NotNullViolation)
    end

    it "存在しないuser_idのレコードは保存できないこと" do
      pay = build(:pay)
      pay.user_id = 0

      expect { pay.save!(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "関連" do
    it "ユーザーは複数の課金記録を持てること" do
      user = create(:user)
      create(:pay, user: user, preset_title: user.preset_titles.first)
      create(:pay, user: user, preset_title: user.preset_titles.second)

      expect(user.pays.count).to eq(2)
    end

    it "ユーザーを削除すると、課金記録とプリセットタイトルも削除されること" do
      user = create(:user)
      create(:pay, user: user, preset_title: user.preset_titles.first)

      expect { user.destroy }
        .to change(Pay, :count).by(-1)
        .and change(PresetTitle, :count).by(-3)
    end

    it "プリセットタイトルから、そのタイトルの課金記録を取得できること" do
      user = create(:user)
      title = user.preset_titles.first
      pay = create(:pay, user: user, preset_title: title)

      expect(title.pays).to include(pay)
    end
  end




  describe "スコープ" do
    let(:user) { create(:user) }

    describe ".in_month" do
      it "指定した月の記録だけを返すこと（月初と月末を含む）" do
        in_first = create(:pay, user: user, paid_at: Date.new(2025, 10, 1))
        in_last = create(:pay, user: user, paid_at: Date.new(2025, 10, 31))
        before_month = create(:pay, user: user, paid_at: Date.new(2025, 9, 30))
        after_month = create(:pay, user: user, paid_at: Date.new(2025, 11, 1))

        result = Pay.in_month(Date.new(2025, 10, 15))

        expect(result).to contain_exactly(in_first, in_last)
        expect(result).not_to include(before_month, after_month)
      end
    end

    describe ".recent_first" do
      it "日付の新しい順に並び、同じ日付なら、新しく作られた記録が先になること" do
        old = create(:pay, user: user, paid_at: Date.new(2025, 10, 1))
        same_day_first = create(:pay, user: user, paid_at: Date.new(2025, 10, 15))
        same_day_second = create(:pay, user: user, paid_at: Date.new(2025, 10, 15))

        expect(Pay.recent_first.to_a).to eq([ same_day_second, same_day_first, old ])
      end
    end
  end
end
