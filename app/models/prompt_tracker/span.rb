# frozen_string_literal: true

# PromptTracker::Span
#
# Represents an individual operation within a trace.
# Spans can be nested to represent hierarchical workflows
# (e.g., a pipeline span containing multiple LLM call spans).
#
# The gem does not ship this model, so it's defined in the host app.
module PromptTracker
  class Span < PromptTracker::ApplicationRecord
    self.table_name = "prompt_tracker_spans"

    # Associations
    belongs_to :trace, class_name: "PromptTracker::Trace", foreign_key: :trace_id
    belongs_to :parent_span, class_name: "PromptTracker::Span", optional: true, foreign_key: :parent_span_id
    has_many :child_spans, class_name: "PromptTracker::Span", foreign_key: :parent_span_id, dependent: :destroy

    belongs_to :llm_response, class_name: "PromptTracker::LlmResponse", optional: true, foreign_key: :llm_response_id

    # Validations
    validates :name, presence: true
    validates :status, presence: true, inclusion: { in: %w[running completed error] }
    validates :started_at, presence: true

    validates :duration_ms,
              numericality: { only_integer: true, greater_than_or_equal_to: 0 },
              allow_nil: true

    validate :metadata_must_be_hash

    # Scopes
    scope :root_spans, -> { where(parent_span_id: nil) }
    scope :running, -> { where(status: "running") }
    scope :completed, -> { where(status: "completed") }
    scope :errored, -> { where(status: "error") }
    scope :of_type, ->(type) { where(span_type: type) }

    private

    def metadata_must_be_hash
      return if metadata.nil? || metadata.is_a?(Hash)

      errors.add(:metadata, "must be a hash")
    end
  end
end
