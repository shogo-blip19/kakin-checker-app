FactoryBot.define do
  factory :budget do
    association :user
    amount { 10_000 }
  end
end
