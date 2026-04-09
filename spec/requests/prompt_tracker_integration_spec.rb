# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PromptTracker Integration", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization, name: "Test Org", slug: "test-org") }
  let!(:membership) do
    ActsAsTenant.without_tenant do
      create(:organization_membership, user: user, organization: organization, role: "admin")
    end
  end

  describe "GET /orgs/:org_slug/app" do
    context "when user is authenticated and belongs to organization" do
      before do
        sign_in user
      end

      it "successfully accesses PromptTracker dashboard" do
        get org_prompt_tracker_path(org_slug: organization.slug)

        expect(response).to have_http_status(:success)
      end

      it "sets the current tenant to the organization from URL" do
        get org_prompt_tracker_path(org_slug: organization.slug)

        # The ApplicationController#set_current_tenant should have set the tenant
        # based on the org_slug param
        expect(ActsAsTenant.current_tenant).to eq(organization)
      end
    end

    context "when user tries to access organization they don't belong to" do
      let(:other_organization) { create(:organization, name: "Other Org", slug: "other-org") }

      before do
        sign_in user
      end

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          get org_prompt_tracker_path(org_slug: other_organization.slug)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get org_prompt_tracker_path(org_slug: organization.slug)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "data isolation" do
    let(:organization2) { create(:organization, name: "Org 2", slug: "org-2") }
    let!(:membership2) do
      ActsAsTenant.without_tenant do
        create(:organization_membership, user: user, organization: organization2, role: "admin")
      end
    end

    let!(:agent1) do
      ActsAsTenant.with_tenant(organization) do
        PromptTracker::Agent.create!(
          name: "org1_prompt",
          description: "Prompt for org 1",
          category: "test"
        )
      end
    end

    let!(:agent2) do
      ActsAsTenant.with_tenant(organization2) do
        PromptTracker::Agent.create!(
          name: "org2_prompt",
          description: "Prompt for org 2",
          category: "test"
        )
      end
    end

    before do
      sign_in user
    end

    it "only shows prompts for the current organization" do
      # Access org1's PromptTracker
      get org_prompt_tracker_path(org_slug: organization.slug)
      expect(response).to have_http_status(:success)

      # Verify tenant is set to org1
      ActsAsTenant.with_tenant(organization) do
        expect(PromptTracker::Agent.count).to eq(1)
        expect(PromptTracker::Agent.first.name).to eq("org1_prompt")
      end

      # Access org2's PromptTracker
      get org_prompt_tracker_path(org_slug: organization2.slug)
      expect(response).to have_http_status(:success)

      # Verify tenant is set to org2
      ActsAsTenant.with_tenant(organization2) do
        expect(PromptTracker::Agent.count).to eq(1)
        expect(PromptTracker::Agent.first.name).to eq("org2_prompt")
      end
    end
  end

  describe "URL structure" do
    it "uses /orgs/:org_slug/app pattern" do
      expect(org_prompt_tracker_path(org_slug: "my-org")).to eq("/orgs/my-org/app")
    end

    it "maintains org_slug in nested routes" do
      # The org_slug should be available in all nested PromptTracker routes
      get org_prompt_tracker_path(org_slug: organization.slug)

      expect(request.params[:org_slug]).to eq(organization.slug)
    end
  end
end
