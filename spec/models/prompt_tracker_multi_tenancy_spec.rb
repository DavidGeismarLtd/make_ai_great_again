# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PromptTracker Multi-Tenancy", type: :model do
  let(:organization1) { create(:organization, name: "Org 1", slug: "org-1") }
  let(:organization2) { create(:organization, name: "Org 2", slug: "org-2") }

  describe "acts_as_tenant configuration" do
    it "adds organization association to PromptTracker::Agent" do
      expect(PromptTracker::Agent.reflect_on_association(:organization)).to be_present
    end

    it "adds organization association to PromptTracker::AgentVersion" do
      expect(PromptTracker::AgentVersion.reflect_on_association(:organization)).to be_present
    end

    it "adds organization association to PromptTracker::Test" do
      expect(PromptTracker::Test.reflect_on_association(:organization)).to be_present
    end

    it "adds organization association to PromptTracker::Dataset" do
      expect(PromptTracker::Dataset.reflect_on_association(:organization)).to be_present
    end

    it "adds organization association to PromptTracker::DatasetRow" do
      expect(PromptTracker::DatasetRow.reflect_on_association(:organization)).to be_present
    end
  end

  describe "data isolation" do
    let!(:agent1) do
      ActsAsTenant.with_tenant(organization1) do
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

    it "isolates prompts by organization" do
      ActsAsTenant.with_tenant(organization1) do
        expect(PromptTracker::Agent.count).to eq(1)
        expect(PromptTracker::Agent.first.name).to eq("org1_prompt")
      end

      ActsAsTenant.with_tenant(organization2) do
        expect(PromptTracker::Agent.count).to eq(1)
        expect(PromptTracker::Agent.first.name).to eq("org2_prompt")
      end
    end

    it "automatically sets organization_id when creating records" do
      ActsAsTenant.with_tenant(organization1) do
        agent = PromptTracker::Agent.create!(
          name: "auto_org_prompt",
          description: "Test auto organization",
          category: "test"
        )
        expect(agent.organization_id).to eq(organization1.id)
      end
    end

    it "prevents accessing records from other organizations" do
      ActsAsTenant.with_tenant(organization1) do
        expect(PromptTracker::Agent.where(id: agent2.id).count).to eq(0)
      end
    end
  end

  describe "nested associations" do
    let!(:agent1) do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::Agent.create!(
          name: "test_prompt_org1",
          description: "Test prompt for org 1",
          category: "test"
        )
      end
    end

    let!(:agent2) do
      ActsAsTenant.with_tenant(organization2) do
        PromptTracker::Agent.create!(
          name: "test_prompt_org2",
          description: "Test prompt for org 2",
          category: "test"
        )
      end
    end

    let!(:version1) do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::AgentVersion.create!(
          agent: agent1,
          user_prompt: "Version 1 for org 1",
          version_number: 1,
          status: "active",
          model_config: { provider: "openai", model: "gpt-4" }
        )
      end
    end

    let!(:version2) do
      ActsAsTenant.with_tenant(organization2) do
        PromptTracker::AgentVersion.create!(
          agent: agent2,
          user_prompt: "Version 1 for org 2",
          version_number: 1,
          status: "active",
          model_config: { provider: "openai", model: "gpt-4" }
        )
      end
    end

    it "isolates prompt versions by organization" do
      ActsAsTenant.with_tenant(organization1) do
        expect(PromptTracker::AgentVersion.count).to eq(1)
        expect(PromptTracker::AgentVersion.first.user_prompt).to eq("Version 1 for org 1")
      end

      ActsAsTenant.with_tenant(organization2) do
        expect(PromptTracker::AgentVersion.count).to eq(1)
        expect(PromptTracker::AgentVersion.first.user_prompt).to eq("Version 1 for org 2")
      end
    end

    it "automatically sets organization_id on nested associations" do
      ActsAsTenant.with_tenant(organization1) do
        expect(version1.organization_id).to eq(organization1.id)
      end

      ActsAsTenant.with_tenant(organization2) do
        expect(version2.organization_id).to eq(organization2.id)
      end
    end
  end

  describe "without tenant set" do
    it "raises error when organization is missing" do
      ActsAsTenant.without_tenant do
        expect {
          PromptTracker::Agent.create!(
            name: "no_tenant_prompt",
            description: "Should fail",
            category: "test"
          )
        }.to raise_error(ActiveRecord::NotNullViolation, /null value in column "organization_id"/)
      end
    end
  end
end
