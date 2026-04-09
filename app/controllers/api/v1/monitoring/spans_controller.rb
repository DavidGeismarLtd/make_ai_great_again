# frozen_string_literal: true

# POST /api/v1/monitoring/spans
#
# Creates a single span within a trace.
# Supports referencing trace/parent_span by either internal id or external_id.
module Api
  module V1
    module Monitoring
      class SpansController < Api::V1::BaseController
        # POST /api/v1/monitoring/spans
        def create
          span = PromptTracker::Span.new(span_params)
          span.organization = ActsAsTenant.current_tenant

          # Resolve trace by external_id if trace_id not provided
          if span.trace_id.blank? && params[:span][:trace_external_id].present?
            trace = PromptTracker::Trace.find_by(external_id: params[:span][:trace_external_id])
            if trace.nil?
              render_error("validation_failed", "Trace not found with external_id: #{params[:span][:trace_external_id]}", status: :unprocessable_entity)
              return
            end
            span.trace_id = trace.id
          end

          # Resolve parent span by external_id if parent_span_id not provided
          if span.parent_span_id.blank? && params[:span][:parent_span_external_id].present?
            parent = PromptTracker::Span.find_by(external_id: params[:span][:parent_span_external_id])
            if parent.nil?
              render_error("validation_failed", "Parent span not found with external_id: #{params[:span][:parent_span_external_id]}", status: :unprocessable_entity)
              return
            end
            span.parent_span_id = parent.id
          end

          if span.save
            render json: {
              id: span.id,
              external_id: span.external_id,
              trace_id: span.trace_id,
              status: span.status,
              created_at: span.created_at
            }, status: :created
          else
            render_validation_errors(span)
          end
        end

        private

        def span_params
          params.require(:span).permit(
            :external_id,
            :trace_id,
            :parent_span_id,
            :name,
            :span_type,
            :input,
            :output,
            :status,
            :started_at,
            :ended_at,
            :duration_ms,
            :llm_response_id,
            metadata: {}
          )
        end
      end
    end
  end
end
