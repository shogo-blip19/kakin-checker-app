FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    transient do
      preset_titles_count { 3 }
    end

    after(:build) do |user, evaluator|
      evaluator.preset_titles_count.times do
        user.preset_titles.build(game_title: "タイトル")
      end
    end
  end
end
