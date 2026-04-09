# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Monitoring::Spans", type: :request do
  let(:organization) { create(:organization) }
  let(:api_key) { ActsAsTenant.with_tenant(organization) { create(:monitoring_api_key, organization: organization) } }
  let(:raw_token) { api_key.raw_token }
  let(:auth_headers) { { "Authorization" => "Bearer #{raw_token}" } }

  let(:trace) do
    ActsAsTenant.with_tenant(organization) do
      PromptTracker::Trace.create!(
        name: "test-trace",
        status: "running",
        started_at: Time.current,
        external_id: "trace-ext-123"
      )
    end
  end

  describe "POST /api/v1/monitoring/spans" do
    let(:valid_params) do
      {
        span: {
          external_id: "span-uuid-123",
          trace_id: trace.id,
          name: "classify-intent",
          span_type: "llm",
          input: "Classify this message",
          status: "completed",
          started_at: "2026-04-09T10:00:01Z",
          ended_at: "2026-04-09T10:00:03Z",
          duration_ms: 2000,
          metadata: { model: "gpt-4o" }
        }
      }
    end

    context "without authentication" do
      it "returns 401" do
        post "/api/v1/monitoring/spans", params: valid_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with valid params" do
      it "creates a span and returns 201" do
        post "/api/v1/monitoring/spans", params: valid_params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body["id"]).to be_present
        expect(body["external_id"]).to eq("span-uuid-123")
        expect(body["trace_id"]).to eq(trace.id)

        ActsAsTenant.with_tenant(organization) do
          expect(PromptTracker::Span.count).to eq(1)
        end
      end
    end

    context "with trace_external_id" do
      it "resolves trace by external_id" do
        # Force-create the trace before the request
        existing_trace = trace

        params = {
          span: {
            external_id: "span-via-ext",
            trace_external_id: "trace-ext-123",
            name: "step-1",
            span_type: "llm",
            status: "completed",
            started_at: Time.current
          }
        }

        post "/api/v1/monitoring/spans", params: params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["trace_id"]).to eq(existing_trace.id)
      end

      it "returns 422 for unknown trace_external_id" do
        params = {
          span: {
            trace_external_id: "nonexistent",
            name: "step-1",
            span_type: "llm",
            status: "completed",
            started_at: Time.current
          }
        }

        post "/api/v1/monitoring/spans", params: params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with parent_span_external_id" do
      it "resolves parent span by external_id" do
        parent_span = ActsAsTenant.with_tenant(organization) do
          PromptTracker::Span.create!(
            trace: trace,
            name: "parent",
            span_type: "chain",
            status: "completed",
            started_at: Time.current,
            external_id: "parent-span-ext"
          )
        end

        params = {
          span: {
            trace_id: trace.id,
            parent_span_external_id: "parent-span-ext",
            name: "child-span",
            span_type: "llm",
            status: "completed",
            started_at: Time.current
          }
        }

        post "/api/v1/monitoring/spans", params: params, headers: auth_headers, as: :json

        expect(response).to have_http_status(:created)
        created_span = ActsAsTenant.with_tenant(organization) { PromptTracker::Span.last }
        expect(created_span.parent_span_id).to eq(parent_span.id)
      end
    end
  end
end
