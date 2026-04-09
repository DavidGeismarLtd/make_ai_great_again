# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PromptTracker Tenant-Scoped Validations", type: :model do
  let(:organization1) { create(:organization, name: "Org 1", slug: "org-1") }
  let(:organization2) { create(:organization, name: "Org 2", slug: "org-2") }

  describe "PromptTracker::Agent uniqueness validations" do
    context "slug uniqueness" do
      it "allows same slug in different organizations" do
        ActsAsTenant.with_tenant(organization1) do
          PromptTracker::Agent.create!(
            name: "Test Prompt 1",
            slug: "shared_slug"
          )
        end

        ActsAsTenant.with_tenant(organization2) do
          agent = PromptTracker::Agent.new(
            name: "Test Prompt 2",
            slug: "shared_slug"
          )
          expect(agent).to be_valid
          expect(agent.save).to be true
        end
      end

      it "prevents duplicate slug within same organization" do
        ActsAsTenant.with_tenant(organization1) do
          PromptTracker::Agent.create!(
            name: "Test Prompt 1",
            slug: "duplicate_slug"
          )

          duplicate = PromptTracker::Agent.new(
            name: "Test Prompt 2",
            slug: "duplicate_slug"
          )
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:slug]).to include("has already been taken")
        end
      end

      it "is case-insensitive within same organization" do
        ActsAsTenant.with_tenant(organization1) do
          PromptTracker::Agent.create!(
            name: "Test Prompt 1",
            slug: "test_slug"
          )

          duplicate = PromptTracker::Agent.new(
            name: "Test Prompt 2",
            slug: "TEST_SLUG"
          )
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:slug]).to include("has already been taken")
        end
      end
    end

    context "name uniqueness" do
      it "allows same name in different organizations" do
        ActsAsTenant.with_tenant(organization1) do
          PromptTracker::Agent.create!(
            name: "Shared Name",
            slug: "shared_name_org1"
          )
        end

        ActsAsTenant.with_tenant(organization2) do
          agent = PromptTracker::Agent.new(
            name: "Shared Name",
            slug: "shared_name_org2"
          )
          expect(agent).to be_valid
          expect(agent.save).to be true
        end
      end

      it "prevents duplicate name within same organization" do
        ActsAsTenant.with_tenant(organization1) do
          PromptTracker::Agent.create!(
            name: "Duplicate Name",
            slug: "duplicate_name_1"
          )

          duplicate = PromptTracker::Agent.new(
            name: "Duplicate Name",
            slug: "duplicate_name_2"
          )
          expect(duplicate).not_to be_valid
          expect(duplicate.errors[:name]).to include("has already been taken")
        end
      end
    end

    context "database verification" do
      it "creates multiple prompts with same slug across organizations" do
        ActsAsTenant.with_tenant(organization1) do
          PromptTracker::Agent.create!(name: "Prompt 1", slug: "test_slug")
        end

        ActsAsTenant.with_tenant(organization2) do
          PromptTracker::Agent.create!(name: "Prompt 2", slug: "test_slug")
        end

        ActsAsTenant.without_tenant do
          agents = PromptTracker::Agent.where(slug: "test_slug")
          expect(agents.count).to eq(2)
          expect(agents.pluck(:organization_id)).to match_array([ organization1.id, organization2.id ])
        end
      end
    end
  end

  describe "PromptTracker::Dataset uniqueness validations" do
    let(:agent_version1) do
      ActsAsTenant.with_tenant(organization1) do
        agent = PromptTracker::Agent.create!(name: "Test Prompt", slug: "test_prompt")
        PromptTracker::AgentVersion.create!(
          agent: agent,
          user_prompt: "Test {{input}}",
          version_number: 1,
          status: "active",
          model_config: { provider: "openai", model: "gpt-4" },
          variables_schema: [ { "name" => "input", "type" => "string", "required" => true } ]
        )
      end
    end

    let(:agent_version2) do
      ActsAsTenant.with_tenant(organization2) do
        agent = PromptTracker::Agent.create!(name: "Test Prompt", slug: "test_prompt")
        PromptTracker::AgentVersion.create!(
          agent: agent,
          user_prompt: "Test {{input}}",
          version_number: 1,
          status: "active",
          model_config: { provider: "openai", model: "gpt-4" },
          variables_schema: [ { "name" => "input", "type" => "string", "required" => true } ]
        )
      end
    end

    it "allows same dataset name for same testable in different organizations" do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::Dataset.create!(
          name: "Shared Dataset",
          testable: agent_version1
        )
      end

      ActsAsTenant.with_tenant(organization2) do
        dataset = PromptTracker::Dataset.new(
          name: "Shared Dataset",
          testable: agent_version2
        )
        expect(dataset).to be_valid
        expect(dataset.save).to be true
      end
    end

    it "prevents duplicate dataset name for same testable within same organization" do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::Dataset.create!(
          name: "Duplicate Dataset",
          testable: agent_version1
        )

        duplicate = PromptTracker::Dataset.new(
          name: "Duplicate Dataset",
          testable: agent_version1
        )
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:name]).to include("has already been taken")
      end
    end
  end

  describe "PromptTracker::EvaluatorConfig uniqueness validations" do
    let(:test1) do
      ActsAsTenant.with_tenant(organization1) do
        agent = PromptTracker::Agent.create!(name: "Test Prompt", slug: "test_prompt")
        version = PromptTracker::AgentVersion.create!(
          agent: agent,
          user_prompt: "Test",
          version_number: 1,
          status: "active",
          model_config: { provider: "openai", model: "gpt-4" }
        )
        PromptTracker::Test.create!(
          testable: version,
          name: "Test 1"
        )
      end
    end

    let(:test2) do
      ActsAsTenant.with_tenant(organization2) do
        agent = PromptTracker::Agent.create!(name: "Test Prompt", slug: "test_prompt")
        version = PromptTracker::AgentVersion.create!(
          agent: agent,
          user_prompt: "Test",
          version_number: 1,
          status: "active",
          model_config: { provider: "openai", model: "gpt-4" }
        )
        PromptTracker::Test.create!(
          testable: version,
          name: "Test 2"
        )
      end
    end

    it "allows same evaluator_type for same configurable in different organizations" do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::EvaluatorConfig.create!(
          configurable: test1,
          evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
          config: { min_length: 10 }
        )
      end

      ActsAsTenant.with_tenant(organization2) do
        evaluator_config = PromptTracker::EvaluatorConfig.new(
          configurable: test2,
          evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
          config: { min_length: 10 }
        )
        expect(evaluator_config).to be_valid
        expect(evaluator_config.save).to be true
      end
    end

    it "prevents duplicate evaluator_type for same configurable within same organization" do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::EvaluatorConfig.create!(
          configurable: test1,
          evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
          config: { min_length: 10 }
        )

        duplicate = PromptTracker::EvaluatorConfig.new(
          configurable: test1,
          evaluator_type: "PromptTracker::Evaluators::LengthEvaluator",
          config: { min_length: 20 }
        )
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:evaluator_type]).to include("has already been taken")
      end
    end
  end

  describe "validation behavior consistency" do
    it "only runs tenant-scoped uniqueness queries" do
      ActsAsTenant.with_tenant(organization1) do
        PromptTracker::Agent.create!(name: "Test", slug: "test_slug")
      end

      ActsAsTenant.with_tenant(organization2) do
        agent = PromptTracker::Agent.new(name: "Test", slug: "test_slug")

        # Capture SQL queries
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
          queries << payload[:sql] if payload[:sql] =~ /SELECT.*FROM.*prompt_tracker_agents.*slug/i
        end

        agent.valid?
        ActiveSupport::Notifications.unsubscribe(subscriber)

        # Should only have queries with organization_id filter
        slug_queries = queries.select { |q| q =~ /slug/i }
        expect(slug_queries).to all(match(/organization_id/i))
      end
    end
  end

  describe "edge cases" do
    it "handles nil values correctly" do
      ActsAsTenant.with_tenant(organization1) do
        # Category can be nil (no validation on it)
        agent = PromptTracker::Agent.new(
          name: "Test",
          slug: "test",
          category: nil
        )
        expect(agent).to be_valid
      end
    end

    it "maintains other validations from the gem" do
      ActsAsTenant.with_tenant(organization1) do
        # Slug format validation should still work
        agent = PromptTracker::Agent.new(
          name: "Test",
          slug: "Invalid Slug!"
        )
        expect(agent).not_to be_valid
        expect(agent.errors[:slug]).to include("must contain only lowercase letters, numbers, and underscores")
      end
    end

    it "requires presence validations" do
      ActsAsTenant.with_tenant(organization1) do
        agent = PromptTracker::Agent.new(slug: "test")
        expect(agent).not_to be_valid
        expect(agent.errors[:name]).to include("can't be blank")
      end
    end
  end
end
