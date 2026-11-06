FactoryBot.define do
  factory :preset_title do
    association :user
    game_title { "タイトル" }
  end
end
