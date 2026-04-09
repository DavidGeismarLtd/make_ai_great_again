# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Monitoring::Ingest", type: :request do
  let(:organization) { create(:organization) }
  let(:api_key) { ActsAsTenant.with_tenant(organization) { create(:monitoring_api_key, organization: organization) } }
  let(:raw_token) { api_key.raw_token }
  let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

  describe "POST /api/v1/monitoring/ingest" do
    let(:full_params) do
      {
        trace: {
          external_id: "trace-ingest-1",
          name: "support-pipeline",
          input: "User asked about refunds",
          output: "Here is our refund policy...",
          status: "completed",
          session_id: "session-abc",
          user_id: "user-123",
          started_at: "2026-04-09T10:00:00Z",
          ended_at: "2026-04-09T10:00:05Z",
          duration_ms: 5000,
          metadata: { environment: "production" }
        },
        spans: [
          {
            external_id: "span-1",
            name: "classify-intent",
            span_type: "llm",
            input: "Classify...",
            output: "refund_request",
            status: "completed",
            started_at: "2026-04-09T10:00:01Z",
            ended_at: "2026-04-09T10:00:03Z",
            duration_ms: 2000,
            llm_response: {
              external_id: "resp-1",
              provider: "openai",
              model: "gpt-4o",
              rendered_prompt: "Classify...",
              response_text: "refund_request",
              status: "success",
              response_time_ms: 1850,
              tokens_prompt: 150,
              tokens_completion: 12,
              tokens_total: 162,
              cost_usd: 0.00243
            }
          },
          {
            external_id: "span-2",
            parent_span_external_id: "span-1",
            name: "generate-response",
            span_type: "llm",
            input: "Generate response...",
            output: "Here is our policy...",
            status: "completed",
            started_at: "2026-04-09T10:00:03Z",
            ended_at: "2026-04-09T10:00:05Z",
            duration_ms: 2000,
            llm_response: {
              external_id: "resp-2",
              provider: "anthropic",
              model: "claude-sonnet-4-20250514",
              response_text: "Here is our refund policy...",
              status: "success",
              response_time_ms: 1900,
              tokens_prompt: 200,
              tokens_completion: 150,
              tokens_total: 350,
              cost_usd: 0.00525
            }
          }
        ]
      }
    end

    context "without authentication" do
      it "returns 401" do
        post "/api/v1/monitoring/ingest", params: full_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid full payload" do
      it "creates trace, spans, and llm_responses in one request" do
        post "/api/v1/monitoring/ingest", params: full_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)

        body = response.parsed_body
        expect(body["trace"]["external_id"]).to eq("trace-ingest-1")
        expect(body["spans"].length).to eq(2)
        expect(body["llm_responses"].length).to eq(2)

        ActsAsTenant.with_tenant(organization) do
          expect(PromptTracker::Trace.count).to eq(1)
          expect(PromptTracker::Span.count).to eq(2)
          expect(PromptTracker::LlmResponse.count).to eq(2)
        end
      end

      it "resolves parent_span_external_id within the batch" do
        post "/api/v1/monitoring/ingest", params: full_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)

        ActsAsTenant.with_tenant(organization) do
          child_span = PromptTracker::Span.find_by(external_id: "span-2")
          parent_span = PromptTracker::Span.find_by(external_id: "span-1")
          expect(child_span.parent_span_id).to eq(parent_span.id)
        end
      end

      it "links spans to their llm_responses" do
        post "/api/v1/monitoring/ingest", params: full_params, headers: auth_headers, as: :json

        ActsAsTenant.with_tenant(organization) do
          span = PromptTracker::Span.find_by(external_id: "span-1")
          expect(span.llm_response_id).to be_present
        end
      end
    end

    context "with trace only (no spans)" do
      it "creates just the trace" do
        params = { trace: full_params[:trace] }

        post "/api/v1/monitoring/ingest", params: params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["trace"]["external_id"]).to eq("trace-ingest-1")

        ActsAsTenant.with_tenant(organization) do
          expect(PromptTracker::Trace.count).to eq(1)
        end
      end
    end

    context "idempotency" do
      it "upserts on duplicate external_id" do
        # First call
        post "/api/v1/monitoring/ingest", params: full_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:created)

        # Second call with same external_ids — should not create duplicates
        post "/api/v1/monitoring/ingest", params: full_params, headers: auth_headers, as: :json
        expect(response).to have_http_status(:created)

        ActsAsTenant.with_tenant(organization) do
          expect(PromptTracker::Trace.where(external_id: "trace-ingest-1").count).to eq(1)
        end
      end
    end
  end
end
