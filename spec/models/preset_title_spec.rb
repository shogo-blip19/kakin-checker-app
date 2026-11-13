require "rails_helper"

RSpec.describe PresetTitle, type: :model do
  describe "バリデーションのテスト" do
    it "正しい入力なら有効であること" do
      preset_title = build(:preset_title)
      expect(preset_title).to be_valid
    end

    context "game_titleのバリデーション" do
      it "空欄の場合は無効であること" do
        preset_title = build(:preset_title, game_title: nil)
        expect(preset_title).to be_invalid
        expect(preset_title.errors[:game_title]).to be_present
      end

      it "20文字を超える場合は無効であること" do
        preset_title = build(:preset_title, game_title: "a" * 21)
        expect(preset_title).to be_invalid
        expect(preset_title.errors[:game_title]).to be_present
      end

      it "20文字以内の場合は有効であること" do
        preset_title = build(:preset_title, game_title: "a" * 20)
        expect(preset_title).to be_valid
      end
    end

    it "空文字が無効であること" do
      preset_title = build(:preset_title, game_title: "")
      expect(preset_title).to be_invalid
      expect(preset_title.errors[:game_title]).to be_present
    end

    it "20文字丁度の場合は有効であること" do
      preset_title = build(:preset_title, game_title: "a" * 20)
      expect(preset_title).to be_valid
    end
  end
end
