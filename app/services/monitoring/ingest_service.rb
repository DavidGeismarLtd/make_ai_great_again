# frozen_string_literal: true

# Monitoring::IngestService
#
# Orchestrates the creation of a complete trace tree (trace + spans + llm_responses)
# in a single database transaction. This is the primary service used by the
# batch ingest API endpoint.
#
# Features:
# - Atomic: all-or-nothing via DB transaction
# - Idempotent: uses external_id to upsert existing records
# - Resolves parent_span_external_id references within the batch
#
# Usage:
#   result = Monitoring::IngestService.call(
#     trace_params: { name: "pipeline", ... },
#     spans_params: [{ name: "step1", llm_response: { ... } }, ...]
#   )
#   result.success?  # => true
#   result.trace     # => PromptTracker::Trace
#   result.spans     # => [PromptTracker::Span, ...]
#   result.llm_responses # => [PromptTracker::LlmResponse, ...]
module Monitoring
  class IngestService
    Result = Struct.new(:success, :trace, :spans, :llm_responses, :error, keyword_init: true) do
      def success? = success
    end

    # @param trace_params [Hash] trace attributes
    # @param spans_params [Array<Hash>] array of span attributes, each may contain :llm_response
    # @return [Result]
    def self.call(trace_params:, spans_params: [])
      new(trace_params:, spans_params:).call
    end

    def initialize(trace_params:, spans_params: [])
      @trace_params = trace_params.to_h.deep_symbolize_keys
      @spans_params = Array(spans_params).map { |s| s.to_h.deep_symbolize_keys }
      @created_spans = []
      @created_llm_responses = []
      # Map external_id → Span for resolving parent references within the batch
      @span_external_id_map = {}
    end

    def call
      ActiveRecord::Base.transaction do
        trace = upsert_trace!
        process_spans!(trace)

        Result.new(
          success: true,
          trace: trace,
          spans: @created_spans,
          llm_responses: @created_llm_responses
        )
      end
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, error: e.message)
    end

    private

    def upsert_trace!
      trace = find_existing_trace
      if trace
        trace.assign_attributes(trace_attributes)
        trace.save!
        trace
      else
        trace = PromptTracker::Trace.new(trace_attributes)
        trace.organization = ActsAsTenant.current_tenant
        trace.save!
        trace
      end
    end

    def find_existing_trace
      return nil if @trace_params[:external_id].blank?

      PromptTracker::Trace.find_by(external_id: @trace_params[:external_id])
    end

    def trace_attributes
      @trace_params.except(:llm_response)
    end

    def process_spans!(trace)
      @spans_params.each do |span_data|
        llm_response_data = span_data.delete(:llm_response)
        span = upsert_span!(trace, span_data)
        @span_external_id_map[span.external_id] = span if span.external_id.present?
        @created_spans << span

        next unless llm_response_data.present?

        llm_response = upsert_llm_response!(trace, span, llm_response_data)
        @created_llm_responses << llm_response

        # Link span to its llm_response
        span.update!(llm_response_id: llm_response.id)
      end
    end

    def upsert_span!(trace, span_data)
      # Resolve parent_span_external_id to parent_span_id
      resolve_parent_span!(span_data)

      existing = find_existing_span(span_data[:external_id])
      if existing
        existing.assign_attributes(span_data.except(:external_id))
        existing.save!
        existing
      else
        span = PromptTracker::Span.new(span_data)
        span.trace_id = trace.id
        span.organization = ActsAsTenant.current_tenant
        span.save!
        span
      end
    end

    def find_existing_span(external_id)
      return nil if external_id.blank?

      PromptTracker::Span.find_by(external_id: external_id)
    end

    def resolve_parent_span!(span_data)
      parent_ext_id = span_data.delete(:parent_span_external_id)
      return if parent_ext_id.blank?
      return if span_data[:parent_span_id].present?

      # First check within this batch
      parent = @span_external_id_map[parent_ext_id]
      # Then check DB
      parent ||= PromptTracker::Span.find_by(external_id: parent_ext_id)

      span_data[:parent_span_id] = parent.id if parent
    end

    def upsert_llm_response!(trace, span, data)
      existing = find_existing_llm_response(data[:external_id])
      if existing
        existing.assign_attributes(data.except(:external_id))
        existing.save!
        existing
      else
        llm_response = PromptTracker::LlmResponse.new(data)
        llm_response.trace_id = trace.id
        llm_response.span_id = span.id
        llm_response.organization = ActsAsTenant.current_tenant
        llm_response.save!
        llm_response
      end
    end

    def find_existing_llm_response(external_id)
      return nil if external_id.blank?

      PromptTracker::LlmResponse.find_by(external_id: external_id)
    end
  end
end
