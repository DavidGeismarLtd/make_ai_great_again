FactoryBot.define do
  factory :organization_membership do
    organization { nil }
    user { nil }
    role { "MyString" }
  end
end
