# frozen_string_literal: true

require "rails_helper"

RSpec.describe MonitoringApiKey, type: :model do
  let(:organization) { create(:organization) }

  before { ActsAsTenant.current_tenant = organization }

  describe "validations" do
    subject { build(:monitoring_api_key, organization: organization) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active revoked]) }
    it { is_expected.to belong_to(:organization).without_validating_presence }
  end

  describe "token generation" do
    it "generates a token on create" do
      key = create(:monitoring_api_key, organization: organization)

      expect(key.raw_token).to be_present
      expect(key.raw_token).to start_with("pt_mon_")
      expect(key.token_digest).to be_present
      expect(key.token_prefix).to eq(key.raw_token[0, 12])
    end

    it "stores SHA-256 digest, not the raw token" do
      key = create(:monitoring_api_key, organization: organization)
      expected_digest = OpenSSL::Digest::SHA256.hexdigest(key.raw_token)

      expect(key.token_digest).to eq(expected_digest)
    end

    it "raw_token is not available on a fresh load from DB" do
      key = create(:monitoring_api_key, organization: organization)
      found = MonitoringApiKey.find(key.id)

      expect(found.raw_token).to be_nil
    end
  end

  describe ".find_by_token" do
    it "finds a key by raw token" do
      key = create(:monitoring_api_key, organization: organization)
      raw = key.raw_token

      # Need to search without tenant scope since find_by_token doesn't use tenant
      found = ActsAsTenant.without_tenant { MonitoringApiKey.find_by_token(raw) }
      expect(found).to eq(key)
    end

    it "returns nil for invalid token" do
      found = ActsAsTenant.without_tenant { MonitoringApiKey.find_by_token("pt_mon_invalid") }
      expect(found).to be_nil
    end

    it "returns nil for blank token" do
      expect(MonitoringApiKey.find_by_token(nil)).to be_nil
      expect(MonitoringApiKey.find_by_token("")).to be_nil
    end
  end

  describe ".find_active_by_token" do
    it "finds an active key" do
      key = create(:monitoring_api_key, organization: organization)
      raw = key.raw_token

      found = ActsAsTenant.without_tenant { MonitoringApiKey.find_active_by_token(raw) }
      expect(found).to eq(key)
    end

    it "does not find a revoked key" do
      key = create(:monitoring_api_key, organization: organization)
      raw = key.raw_token
      key.revoke!

      found = ActsAsTenant.without_tenant { MonitoringApiKey.find_active_by_token(raw) }
      expect(found).to be_nil
    end
  end

  describe "#revoke!" do
    it "marks the key as revoked" do
      key = create(:monitoring_api_key, organization: organization)
      key.revoke!

      expect(key.reload.status).to eq("revoked")
      expect(key.revoked_at).to be_present
      expect(key).to be_revoked
      expect(key).not_to be_active
    end
  end

  describe "#touch_last_used!" do
    it "updates last_used_at" do
      key = create(:monitoring_api_key, organization: organization)
      expect(key.last_used_at).to be_nil

      key.touch_last_used!
      expect(key.reload.last_used_at).to be_present
    end
  end

  describe "scopes" do
    it ".active returns only active keys" do
      active_key = create(:monitoring_api_key, organization: organization)
      create(:monitoring_api_key, :revoked, organization: organization)

      expect(MonitoringApiKey.active).to eq([ active_key ])
    end

    it ".revoked returns only revoked keys" do
      create(:monitoring_api_key, organization: organization)
      revoked_key = create(:monitoring_api_key, :revoked, organization: organization)

      expect(MonitoringApiKey.revoked).to eq([ revoked_key ])
    end
  end
end
