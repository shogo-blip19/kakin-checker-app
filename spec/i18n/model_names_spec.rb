require "rails_helper"

RSpec.describe "モデルの日本語化" do
  describe "モデル名" do
    it "各モデルの名前が日本語で表示される" do
      expect(User.model_name.human).to eq("ユーザー")
      expect(PresetTitle.model_name.human).to eq("プリセットタイトル")
      expect(Budget.model_name.human).to eq("予算")
    end
  end

  describe "項目名" do
    it "Userの項目名が日本語で表示される" do
      expect(User.human_attribute_name(:email)).to eq("メールアドレス")
      expect(User.human_attribute_name(:password)).to eq("パスワード")
      expect(User.human_attribute_name(:password_confirmation)).to eq("パスワード（確認）")
    end

    it "PresetTitleの項目名が日本語で表示される" do
      expect(PresetTitle.human_attribute_name(:game_title)).to eq("ゲームタイトル")
    end

    it "Budgetの項目名が日本語で表示される" do
      expect(Budget.human_attribute_name(:amount)).to eq("予算額")
    end
  end

  describe "エラーメッセージ" do
    it "Userのメールアドレスが空のとき、日本語のメッセージが出る" do
      user = build(:user, email: nil)
      user.valid?

      expect(user.errors.full_messages).to include("メールアドレスを入力してください")
    end

    it "プリセットタイトルが3件でないとき、件数のメッセージが出る" do
      user = build(:user, preset_titles_count: 2)
      user.valid?

      expect(user.errors.full_messages).to include("プリセットタイトルは3件にしてください")
    end
  end
end
