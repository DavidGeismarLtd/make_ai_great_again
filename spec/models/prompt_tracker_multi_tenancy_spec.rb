# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PromptTracker Multi-Tenancy", type: :model do
  let(:organization1) { create(:organization, name: "Org 1", slug: "org-1") }
  let(:organization2) { create(:organization, name: "Org 2", slug: "org-2") }

  describe "acts_as_tenant configuration" do
    it "adds organization association to PromptTracker::Prompt" do
      expect(PromptTracker::Prompt.reflect_on_association(:organization)).to be_present
    end

    it "adds organization association to PromptTracker::PromptVersion" do
      expect(PromptTracker::PromptVersion.reflect_on_association(:organization)).to be_present
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
    let!(:prompt1) do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::Prompt.create!(
          name: "org1_prompt",
          description: "Prompt for org 1",
          category: "test"
        )
      end
    end

    let!(:prompt2) do
      ActsAsTenant.with_tenant(organization2) do
        PromptTracker::Prompt.create!(
          name: "org2_prompt",
          description: "Prompt for org 2",
          category: "test"
        )
      end
    end

    it "isolates prompts by organization" do
      ActsAsTenant.with_tenant(organization1) do
        expect(PromptTracker::Prompt.count).to eq(1)
        expect(PromptTracker::Prompt.first.name).to eq("org1_prompt")
      end

      ActsAsTenant.with_tenant(organization2) do
        expect(PromptTracker::Prompt.count).to eq(1)
        expect(PromptTracker::Prompt.first.name).to eq("org2_prompt")
      end
    end

    it "automatically sets organization_id when creating records" do
      ActsAsTenant.with_tenant(organization1) do
        prompt = PromptTracker::Prompt.create!(
          name: "auto_org_prompt",
          description: "Test auto organization",
          category: "test"
        )
        expect(prompt.organization_id).to eq(organization1.id)
      end
    end

    it "prevents accessing records from other organizations" do
      ActsAsTenant.with_tenant(organization1) do
        expect(PromptTracker::Prompt.where(id: prompt2.id).count).to eq(0)
      end
    end
  end

  describe "nested associations" do
    let!(:prompt1) do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::Prompt.create!(
          name: "test_prompt_org1",
          description: "Test prompt for org 1",
          category: "test"
        )
      end
    end

    let!(:prompt2) do
      ActsAsTenant.with_tenant(organization2) do
        PromptTracker::Prompt.create!(
          name: "test_prompt_org2",
          description: "Test prompt for org 2",
          category: "test"
        )
      end
    end

    let!(:version1) do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::PromptVersion.create!(
          prompt: prompt1,
          user_prompt: "Version 1 for org 1",
          status: "active",
          model_config: { provider: "openai", model: "gpt-4" }
        )
      end
    end

    let!(:version2) do
      ActsAsTenant.with_tenant(organization2) do
        PromptTracker::PromptVersion.create!(
          prompt: prompt2,
          user_prompt: "Version 1 for org 2",
          status: "active",
          model_config: { provider: "openai", model: "gpt-4" }
        )
      end
    end

    it "isolates prompt versions by organization" do
      ActsAsTenant.with_tenant(organization1) do
        expect(PromptTracker::PromptVersion.count).to eq(1)
        expect(PromptTracker::PromptVersion.first.user_prompt).to eq("Version 1 for org 1")
      end

      ActsAsTenant.with_tenant(organization2) do
        expect(PromptTracker::PromptVersion.count).to eq(1)
        expect(PromptTracker::PromptVersion.first.user_prompt).to eq("Version 1 for org 2")
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
          PromptTracker::Prompt.create!(
            name: "no_tenant_prompt",
            description: "Should fail",
            category: "test"
          )
        }.to raise_error(ActiveRecord::NotNullViolation, /null value in column "organization_id"/)
      end
    end
  end
end
