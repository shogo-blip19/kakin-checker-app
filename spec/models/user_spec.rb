require 'rails_helper'

RSpec.describe User, type: :model do
  describe "バリデーションのテスト" do
    it "正しい入力なら有効であること" do
      user = build(:user)

      expect(user).to be_valid
    end

    context "preset_titlesのバリデーション" do
      it "preset_titlesが3つ未満の場合は無効であること" do
        user = build(:user, preset_titles_count: 2)

        expect(user).to be_invalid
        expect(user.errors[:preset_titles]).to be_present
      end

      it "preset_titlesが4つ以上の場合は無効であること" do
        user = build(:user, preset_titles_count: 4)

        expect(user).to be_invalid
        expect(user.errors[:preset_titles]).to be_present
      end

      it "preset_titlesが0の場合は無効であること" do
        user = build(:user, preset_titles_count: 0)

        expect(user).to be_invalid
        expect(user.errors[:preset_titles]).to be_present
      end
    end

    context "emailのバリデーション" do
      it "emailが空欄の場合は無効であること" do
        user = build(:user, email: nil)

        expect(user).to be_invalid
        expect(user.errors[:email]).to be_present
      end

      it "emailが重複している場合は無効であること" do
        create(:user, email: "test@example.com")
        user = build(:user, email: "test@example.com")

        expect(user).to be_invalid
        expect(user.errors[:email]).to be_present
      end

      it "emailが正しい形式でない場合は無効であること" do
        user = build(:user, email: "invalid_email")

        expect(user).to be_invalid
        expect(user.errors[:email]).to be_present
      end
    end
    context "passwordのバリデーション" do
      it "passwordが空欄の場合は無効であること" do
        user = build(:user, password: nil)

        expect(user).to be_invalid
        expect(user.errors[:password]).to be_present
      end

      it "password_confirmationが空欄の場合は無効であること" do
        user = build(:user, password_confirmation: nil)

        expect(user).to be_invalid
        expect(user.errors[:password_confirmation]).to be_present
      end

      it "passwordが" "である場合は無効であること" do
        user = build(:user, password: "")

        expect(user).to be_invalid
        expect(user.errors[:password]).to be_present
      end

      it "passwordが8文字未満の場合は無効であること" do
        user = build(:user, password: "short")

        expect(user).to be_invalid
        expect(user.errors[:password]).to be_present
      end

      it "passwordとpassword_confirmationが一致しない場合は無効であること" do
        user = build(:user, password: "password", password_confirmation: "different")

        expect(user).to be_invalid
        expect(user.errors[:password_confirmation]).to be_present
      end

      it "passwordがそのまま保存されていないこと" do
        user = create(:user, password: "password", password_confirmation: "password")

        expect(user.crypted_password).to be_present
        expect(user.crypted_password).not_to eq("password")
      end
    end

    context "登録済みのユーザーを更新するとき" do
  it "パスワードを変更しなければ、メールアドレスだけ変更できる" do
    user = User.find(create(:user).id)
    user.email = "changed@example.com"
    expect(user).to be_valid
  end

  it "パスワードを変更するとき、8文字未満だと無効である" do
    user = User.find(create(:user).id)
    user.password = "short"
    user.password_confirmation = "short"
    expect(user).to be_invalid
    end
  end
end

describe "関連" do
  context "preset_titlesとの関係" do
    it "ユーザーが削除されると、関連するpreset_titlesも削除されること" do
      user = create(:user)

      expect { user.destroy }.to change(PresetTitle, :count).by(-3)
    end
  end

  context "budgetとの関係" do
    it "ユーザーが削除されると、関連する予算も削除されること" do
      user = create(:user)
      create(:budget, user: user)
      user.destroy
      expect(Budget.find_by(user: user)).to be_nil
    end

    it "同じユーザーに対して複数の予算を作成できないこと" do
      user = create(:user)
      create(:budget, user: user)

      expect { create(:budget, user: user) }.to raise_error(ActiveRecord::RecordNotUnique)
    end


    it "予算がなくても、ユーザーは有効であること" do
      user = build(:user)

      expect(user).to be_valid
      expect(user.budget).to be_nil
    end
  end
  end

  describe "#over_budget_in_month?" do
    let(:user) { create(:user) }
    let(:date) { Date.new(2025, 10, 15) }

    def add_pay(amount, paid_at: date, owner: user)
      create(:pay, user: owner, preset_title: owner.preset_titles.order(:id).first, amount: amount, paid_at: paid_at)
    end

    it "予算が未設定なら、合計がどれだけ大きくても、falseであること" do
      add_pay(999_999)

      expect(user.over_budget_in_month?(date)).to be(false)
    end

    context "予算が50,000円のとき" do
      before { create(:budget, user: user, amount: 50_000) }

      it "記録がなければ、falseであること" do
        expect(user.over_budget_in_month?(date)).to be(false)
      end

      it "合計が予算より少なければ、falseであること" do
        add_pay(49_999)

        expect(user.over_budget_in_month?(date)).to be(false)
      end

      it "合計が予算とちょうど同じなら、falseであること" do
        add_pay(50_000)

        expect(user.over_budget_in_month?(date)).to be(false)
      end

      it "合計が予算を1円でも超えたら、trueであること" do
        add_pay(50_001)

        expect(user.over_budget_in_month?(date)).to be(true)
      end

      it "複数の記録の合計で判定すること" do
        add_pay(30_000)
        add_pay(20_001, paid_at: Date.new(2025, 10, 1))

        expect(user.over_budget_in_month?(date)).to be(true)
      end

      it "ほかの月の記録は、合計に含めないこと" do
        add_pay(99_999, paid_at: Date.new(2025, 9, 30))
        add_pay(88_888, paid_at: Date.new(2025, 11, 1))

        expect(user.over_budget_in_month?(date)).to be(false)
      end

      it "ほかのユーザーの記録は、合計に含めないこと" do
        add_pay(70_000, owner: create(:user))

        expect(user.over_budget_in_month?(date)).to be(false)
      end

      it "日付を指定しないときは、今月で判定すること" do
        add_pay(60_000, paid_at: Date.current)

        expect(user.over_budget_in_month?).to be(true)
      end
    end
  end
end
