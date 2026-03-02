# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserRegistrationService do
  describe ".call" do
    let(:user) do
      User.new(
        first_name: "John",
        last_name: "Doe",
        email: "john@example.com",
        password: "password123",
        password_confirmation: "password123"
      )
    end

    context "with valid user" do
      it "creates the user" do
        expect {
          described_class.call(user)
        }.to change(User, :count).by(1)
      end

      it "creates an organization" do
        expect {
          described_class.call(user)
        }.to change(Organization, :count).by(1)
      end

      it "creates an organization membership" do
        expect {
          described_class.call(user)
        }.to change {
          ActsAsTenant.without_tenant { OrganizationMembership.count }
        }.by(1)
      end

      it "creates an organization configuration" do
        expect {
          described_class.call(user)
        }.to change(OrganizationConfiguration, :count).by(1)
      end

      it "returns success" do
        result = described_class.call(user)
        expect(result.success?).to be true
      end

      it "sets organization name based on user's first name" do
        result = described_class.call(user)
        expect(result.organization.name).to eq("John's Organization")
      end

      it "sets user as owner of organization" do
        result = described_class.call(user)

        membership = ActsAsTenant.without_tenant do
          OrganizationMembership.find_by(user: user, organization: result.organization)
        end

        expect(membership.role).to eq("owner")
      end

      it "sets organization status to active" do
        result = described_class.call(user)
        expect(result.organization.status).to eq("active")
      end
    end

    context "with invalid user" do
      let(:invalid_user) do
        User.new(
          first_name: "",
          last_name: "Doe",
          email: "john@example.com",
          password: "password123",
          password_confirmation: "password123"
        )
      end

      it "does not create the user" do
        expect {
          described_class.call(invalid_user)
        }.not_to change(User, :count)
      end

      it "does not create an organization" do
        expect {
          described_class.call(invalid_user)
        }.not_to change(Organization, :count)
      end

      it "does not create an organization membership" do
        expect {
          described_class.call(invalid_user)
        }.not_to change {
          ActsAsTenant.without_tenant { OrganizationMembership.count }
        }
      end

      it "returns failure" do
        result = described_class.call(invalid_user)
        expect(result.success?).to be false
      end

      it "includes error messages" do
        result = described_class.call(invalid_user)
        expect(result.errors).not_to be_empty
      end
    end

    context "transaction rollback" do
      it "rolls back all changes if organization creation fails" do
        # Stub organization creation to fail
        allow_any_instance_of(Organization).to receive(:persisted?).and_return(false)

        expect {
          described_class.call(user)
        }.not_to change(User, :count)
      end

      it "rolls back all changes if membership creation fails" do
        # Stub membership creation to fail
        allow_any_instance_of(OrganizationMembership).to receive(:persisted?).and_return(false)

        expect {
          described_class.call(user)
        }.not_to change(User, :count)
      end

      it "rolls back all changes if configuration creation fails" do
        # Stub configuration creation to fail
        allow_any_instance_of(OrganizationConfiguration).to receive(:persisted?).and_return(false)

        expect {
          described_class.call(user)
        }.not_to change(User, :count)
      end
    end
  end
end
