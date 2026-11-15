FactoryBot.define do
  factory :pay do
    association :user
    amount { 1000 }
    paid_at { Date.current }

    preset_title { user.preset_titles.first }
  end
end
