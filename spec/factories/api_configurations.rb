FactoryBot.define do
  factory :api_configuration do
    organization { nil }
    provider { "MyString" }
    key_name { "MyString" }
    encrypted_api_key { "MyText" }
    is_active { false }
    last_validated_at { "2026-02-24 11:32:50" }
  end
end
