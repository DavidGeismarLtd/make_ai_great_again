FactoryBot.define do
  factory :organization_invitation do
    association :organization
    association :invited_by, factory: :user
    sequence(:email) { |n| "invitee#{n}@example.com" }
    role { "member" }
    expires_at { 7.days.from_now }
    accepted_at { nil }

    trait :admin do
      role { "admin" }
    end

    trait :viewer do
      role { "viewer" }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :accepted do
      accepted_at { 1.day.ago }
    end
  end
end
