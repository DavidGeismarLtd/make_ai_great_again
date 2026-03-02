# frozen_string_literal: true

require "rails_helper"

RSpec.describe "User Registration", type: :request do
  describe "POST /users" do
    let(:valid_attributes) do
      {
        user: {
          first_name: "David",
          last_name: "Geismar",
          email: "david@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post user_registration_path, params: valid_attributes
        }.to change(User, :count).by(1)
      end

      it "creates an organization for the user" do
        expect {
          post user_registration_path, params: valid_attributes
        }.to change(Organization, :count).by(1)
      end

      it "creates an organization membership" do
        expect {
          post user_registration_path, params: valid_attributes
        }.to change {
          ActsAsTenant.without_tenant { OrganizationMembership.count }
        }.by(1)
      end

      it "creates an organization configuration" do
        expect {
          post user_registration_path, params: valid_attributes
        }.to change(OrganizationConfiguration, :count).by(1)
      end

      it "sets the user as owner of the organization" do
        post user_registration_path, params: valid_attributes

        user = User.last
        membership = ActsAsTenant.without_tenant do
          OrganizationMembership.find_by(user: user)
        end

        expect(membership.role).to eq("owner")
      end

      it "auto-generates organization name based on user's first name" do
        post user_registration_path, params: valid_attributes

        organization = Organization.last
        expect(organization.name).to eq("David's Organization")
      end

      it "auto-generates organization slug" do
        post user_registration_path, params: valid_attributes

        organization = Organization.last
        expect(organization.slug).to eq("david-s-organization")
      end

      it "signs in the user" do
        post user_registration_path, params: valid_attributes

        expect(controller.current_user).to be_present
        expect(controller.current_user.email).to eq("david@example.com")
      end

      it "redirects to testing dashboard" do
        post user_registration_path, params: valid_attributes

        organization = Organization.last
        expect(response).to redirect_to("/orgs/#{organization.slug}/app/testing")
      end

      it "sets default user role" do
        post user_registration_path, params: valid_attributes

        user = User.last
        expect(user.role).to eq("user")
      end
    end

    context "with invalid parameters" do
      it "does not create a user when email is missing" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:user][:email] = ""

        expect {
          post user_registration_path, params: invalid_attributes
        }.not_to change(User, :count)
      end

      it "does not create a user when first_name is missing" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:user][:first_name] = ""

        expect {
          post user_registration_path, params: invalid_attributes
        }.not_to change(User, :count)
      end

      it "does not create a user when last_name is missing" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:user][:last_name] = ""

        expect {
          post user_registration_path, params: invalid_attributes
        }.not_to change(User, :count)
      end

      it "does not create a user when password is too short" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:user][:password] = "12345"
        invalid_attributes[:user][:password_confirmation] = "12345"

        expect {
          post user_registration_path, params: invalid_attributes
        }.not_to change(User, :count)
      end

      it "does not create organization when user creation fails" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:user][:email] = ""

        expect {
          post user_registration_path, params: invalid_attributes
        }.not_to change(Organization, :count)
      end

      it "renders the signup form again with errors" do
        invalid_attributes = valid_attributes.deep_dup
        invalid_attributes[:user][:email] = ""

        post user_registration_path, params: invalid_attributes

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
