FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Test Organization #{n}" }
    sequence(:slug) { |n| "test-organization-#{n}" }
    status { "active" }
  end
end
