# frozen_string_literal: true

require "rails_helper"

RSpec.describe Monitoring::IngestService do
  let(:organization) { create(:organization) }

  before { ActsAsTenant.current_tenant = organization }

  describe ".call" do
    let(:trace_params) do
      {
        external_id: "trace-svc-1",
        name: "test-pipeline",
        input: "Hello",
        status: "completed",
        started_at: Time.current,
        ended_at: Time.current + 5.seconds,
        duration_ms: 5000
      }
    end

    let(:spans_params) do
      [
        {
          external_id: "span-svc-1",
          name: "step-1",
          span_type: "llm",
          status: "completed",
          started_at: Time.current,
          ended_at: Time.current + 2.seconds,
          duration_ms: 2000,
          llm_response: {
            external_id: "resp-svc-1",
            provider: "openai",
            model: "gpt-4o",
            response_text: "Hello back",
            status: "success",
            tokens_prompt: 10,
            tokens_completion: 5,
            tokens_total: 15
          }
        }
      ]
    end

    context "with valid params" do
      it "creates trace, span, and llm_response" do
        result = described_class.call(trace_params: trace_params, spans_params: spans_params)

        expect(result).to be_success
        expect(result.trace).to be_persisted
        expect(result.trace.external_id).to eq("trace-svc-1")
        expect(result.spans.length).to eq(1)
        expect(result.llm_responses.length).to eq(1)
      end

      it "links span to llm_response" do
        result = described_class.call(trace_params: trace_params, spans_params: spans_params)

        expect(result.spans.first.llm_response_id).to eq(result.llm_responses.first.id)
      end

      it "sets organization on all records" do
        result = described_class.call(trace_params: trace_params, spans_params: spans_params)

        expect(result.trace.organization_id).to eq(organization.id)
        expect(result.spans.first.organization_id).to eq(organization.id)
        expect(result.llm_responses.first.organization_id).to eq(organization.id)
      end
    end

    context "with trace only" do
      it "creates trace without spans" do
        result = described_class.call(trace_params: trace_params, spans_params: [])

        expect(result).to be_success
        expect(result.trace).to be_persisted
        expect(result.spans).to be_empty
        expect(result.llm_responses).to be_empty
      end
    end

    context "with parent_span_external_id resolution" do
      it "resolves parent within the batch" do
        spans = [
          {
            external_id: "parent-span",
            name: "parent",
            span_type: "chain",
            status: "completed",
            started_at: Time.current
          },
          {
            external_id: "child-span",
            parent_span_external_id: "parent-span",
            name: "child",
            span_type: "llm",
            status: "completed",
            started_at: Time.current
          }
        ]

        result = described_class.call(trace_params: trace_params, spans_params: spans)

        expect(result).to be_success
        child = result.spans.find { |s| s.external_id == "child-span" }
        parent = result.spans.find { |s| s.external_id == "parent-span" }
        expect(child.parent_span_id).to eq(parent.id)
      end
    end

    context "idempotency (upsert)" do
      it "updates existing trace on duplicate external_id" do
        described_class.call(trace_params: trace_params, spans_params: [])

        updated_params = trace_params.merge(output: "Updated output")
        result = described_class.call(trace_params: updated_params, spans_params: [])

        expect(result).to be_success
        expect(PromptTracker::Trace.where(external_id: "trace-svc-1").count).to eq(1)
        expect(result.trace.output).to eq("Updated output")
      end
    end

    context "transaction rollback" do
      it "rolls back all records on validation failure" do
        bad_spans = [
          {
            external_id: "span-ok",
            name: "ok-span",
            span_type: "llm",
            status: "completed",
            started_at: Time.current
          },
          {
            # Missing required name field
            external_id: "span-bad",
            span_type: "llm",
            status: "completed",
            started_at: Time.current
          }
        ]

        result = described_class.call(trace_params: trace_params, spans_params: bad_spans)

        expect(result).not_to be_success
        expect(result.error).to be_present
        # Transaction should have rolled back — no trace created
        expect(PromptTracker::Trace.where(external_id: "trace-svc-1").count).to eq(0)
      end
    end
  end
end
