# frozen_string_literal: true

FactoryBot.define do
  factory :monitoring_api_key do
    organization
    sequence(:name) { |n| "API Key #{n}" }
    created_by { "test@example.com" }
    status { "active" }

    trait :revoked do
      status { "revoked" }
      revoked_at { Time.current }
    end
  end
end
