FactoryBot.define do
  factory :pay do
    user { nil }
    preset_title { nil }
    amount { 1 }
    paid_at { "2026-11-14" }
  end
end
