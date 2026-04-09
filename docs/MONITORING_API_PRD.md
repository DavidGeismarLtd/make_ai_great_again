# Monitoring API — Product Requirements Document

## 1. Overview

### Problem
The PromptTracker gem currently provides monitoring (traces, spans, LLM responses) via a `track_llm_call` helper embedded directly in Rails projects. This only works for applications that bundle the gem. As a SaaS platform, we need to allow **any application** (Ruby, Python, Node.js, etc.) to send monitoring data via HTTP API, authenticated with an organization-scoped API key.

### Solution
Build a JSON REST API at `/api/v1/monitoring/` that accepts traces, spans, and LLM response data from external SDKs. Authentication is via a new `MonitoringApiKey` model tied to an organization, which resolves the tenant without Devise session auth.

### Goals
- Allow any application to send LLM observability data to the platform
- Maintain full multi-tenancy isolation via API key → organization mapping
- Support both individual resource creation and batch ingestion
- Provide idempotent writes for safe SDK retries
- Keep the API surface minimal and SDK-friendly

### Non-Goals (v1)
- Read/query APIs (monitoring data is viewed via the existing web UI)
- SDK gem implementation (separate project, after API is stable)
- Rate limiting (can be added via Rack middleware later)
- Webhook/streaming support

---

## 2. Architecture

### 2.1 Authentication Flow

```
SDK → POST /api/v1/monitoring/ingest
      Header: Authorization: Bearer <monitoring_api_key>
      ↓
Api::V1::BaseController
      ↓ authenticate_with_api_key!
      ↓ finds MonitoringApiKey by token
      ↓ sets ActsAsTenant.current_tenant = api_key.organization
      ↓
Api::V1::Monitoring::IngestController
      ↓ creates Trace, Spans, LlmResponses
      ↓ returns 201 with created IDs
```

### 2.2 Controller Hierarchy

```
ActionController::API
  └── Api::V1::BaseController          # Bearer token auth, tenant resolution, JSON error handling
        └── Api::V1::Monitoring::TracesController
        └── Api::V1::Monitoring::SpansController
        └── Api::V1::Monitoring::LlmResponsesController
        └── Api::V1::Monitoring::IngestController   # Batch endpoint
```

### 2.3 Route Structure

```ruby
# config/routes.rb
namespace :api do
  namespace :v1 do
    namespace :monitoring do
      resources :traces, only: [:create]
      resources :spans, only: [:create]
      resources :llm_responses, only: [:create]
      post :ingest, to: "ingest#create"
    end
  end
end
```

---

## 3. Data Model Changes

### 3.1 New Model: `MonitoringApiKey`

| Column | Type | Notes |
|---|---|---|
| `id` | bigint | PK |
| `organization_id` | bigint | FK, NOT NULL |
| `name` | string | Human label, e.g. "Production Key" |
| `token` | string | The bearer token (generated, unique, indexed) |
| `status` | string | `active` / `revoked`, default `active` |
| `last_used_at` | datetime | Updated on each API call |
| `created_by` | string | Email of user who created it |
| `revoked_at` | datetime | When the key was revoked |
| `timestamps` | | |

- Token format: `pt_mon_` prefix + 32-char SecureRandom hex (total ~39 chars)
- Token is stored as a SHA-256 digest for security; the raw token is shown only once at creation
- `acts_as_tenant :organization`

### 3.2 Schema Changes to Existing Tables

#### `prompt_tracker_llm_responses`
- **Make `agent_version_id` nullable** — External SDK calls won't always have an agent configured in the platform
- **Make `rendered_prompt` nullable** — SDK may send raw messages instead
- Add `external_id` (string, unique per org) — Client-generated UUID for idempotency

#### `prompt_tracker_traces`
- Add `external_id` (string, unique per org) — Client-generated UUID for idempotency

#### `prompt_tracker_spans`
- Add `external_id` (string, unique per org) — Client-generated UUID for idempotency
- Add `llm_response_id` (bigint, nullable, FK) — Direct link from span to its LLM response

---

## 4. API Endpoints

### 4.1 POST `/api/v1/monitoring/traces`

Creates a single trace.

**Request:**
```json
{
  "trace": {
    "external_id": "uuid-from-sdk",
    "name": "customer-support-pipeline",
    "input": "User asked about refund policy",
    "status": "running",
    "session_id": "session-abc",
    "user_id": "user-123",
    "started_at": "2026-04-09T10:00:00Z",
    "metadata": { "environment": "production" }
  }
}
```

**Response (201):**
```json
{
  "id": 42,
  "external_id": "uuid-from-sdk",
  "status": "running",
  "created_at": "2026-04-09T10:00:00Z"
}
```


### 4.2 POST `/api/v1/monitoring/spans`

Creates a single span within an existing trace.

**Request:**
```json
{
  "span": {
    "external_id": "span-uuid-from-sdk",
    "trace_id": 42,
    "trace_external_id": "uuid-from-sdk",
    "parent_span_id": null,
    "parent_span_external_id": null,
    "name": "llm-call-classify-intent",
    "span_type": "llm",
    "input": "Classify the following user message...",
    "status": "completed",
    "started_at": "2026-04-09T10:00:01Z",
    "ended_at": "2026-04-09T10:00:03Z",
    "duration_ms": 2000,
    "metadata": { "model": "gpt-4o" }
  }
}
```

Note: The caller can reference the parent trace/span by **either** internal `id` or `external_id`. The controller resolves accordingly.

**Response (201):**
```json
{
  "id": 101,
  "external_id": "span-uuid-from-sdk",
  "trace_id": 42,
  "status": "completed",
  "created_at": "2026-04-09T10:00:01Z"
}
```

### 4.3 POST `/api/v1/monitoring/llm_responses`

Creates a single LLM response record, optionally linked to a span/trace.

**Request:**
```json
{
  "llm_response": {
    "external_id": "resp-uuid-from-sdk",
    "trace_id": 42,
    "span_id": 101,
    "provider": "openai",
    "model": "gpt-4o",
    "rendered_prompt": "Classify the following...",
    "rendered_system_prompt": "You are a classifier.",
    "response_text": "intent: refund_request",
    "status": "success",
    "response_time_ms": 1850,
    "tokens_prompt": 150,
    "tokens_completion": 12,
    "tokens_total": 162,
    "cost_usd": 0.00243,
    "environment": "production",
    "user_id": "user-123",
    "session_id": "session-abc",
    "metadata": {}
  }
}
```

**Response (201):**
```json
{
  "id": 501,
  "external_id": "resp-uuid-from-sdk",
  "status": "success",
  "created_at": "2026-04-09T10:00:03Z"
}
```

### 4.4 POST `/api/v1/monitoring/ingest` ⭐ Primary SDK Endpoint

Batch endpoint that accepts a complete trace tree in a single request. This is the **recommended endpoint for SDKs** as it reduces HTTP roundtrips and ensures atomicity.

**Request:**
```json
{
  "trace": {
    "external_id": "trace-uuid",
    "name": "customer-support-pipeline",
    "input": "User asked about refund policy",
    "output": "Here is our refund policy...",
    "status": "completed",
    "session_id": "session-abc",
    "user_id": "user-123",
    "started_at": "2026-04-09T10:00:00Z",
    "ended_at": "2026-04-09T10:00:05Z",
    "duration_ms": 5000,
    "metadata": { "environment": "production" }
  },
  "spans": [
    {
      "external_id": "span-1-uuid",
      "name": "classify-intent",
      "span_type": "llm",
      "input": "Classify...",
      "output": "refund_request",
      "status": "completed",
      "started_at": "2026-04-09T10:00:01Z",
      "ended_at": "2026-04-09T10:00:03Z",
      "duration_ms": 2000,
      "metadata": {},
      "llm_response": {
        "external_id": "resp-1-uuid",
        "provider": "openai",
        "model": "gpt-4o",
        "rendered_prompt": "Classify the following...",
        "response_text": "refund_request",
        "status": "success",
        "response_time_ms": 1850,
        "tokens_prompt": 150,
        "tokens_completion": 12,
        "tokens_total": 162,
        "cost_usd": 0.00243
      }
    },
    {
      "external_id": "span-2-uuid",
      "parent_span_external_id": "span-1-uuid",
      "name": "generate-response",
      "span_type": "llm",
      "input": "Generate a response for refund...",
      "output": "Here is our refund policy...",
      "status": "completed",
      "started_at": "2026-04-09T10:00:03Z",
      "ended_at": "2026-04-09T10:00:05Z",
      "duration_ms": 2000,
      "metadata": {},
      "llm_response": {
        "external_id": "resp-2-uuid",
        "provider": "anthropic",
        "model": "claude-sonnet-4-20250514",
        "rendered_prompt": "Generate a helpful response...",
        "response_text": "Here is our refund policy...",
        "status": "success",
        "response_time_ms": 1900,
        "tokens_prompt": 200,
        "tokens_completion": 150,
        "tokens_total": 350,
        "cost_usd": 0.00525
      }
    }
  ]
}
```

**Response (201):**
```json
{
  "trace": { "id": 42, "external_id": "trace-uuid" },
  "spans": [
    { "id": 101, "external_id": "span-1-uuid" },
    { "id": 102, "external_id": "span-2-uuid" }
  ],
  "llm_responses": [
    { "id": 501, "external_id": "resp-1-uuid" },
    { "id": 502, "external_id": "resp-2-uuid" }
  ]
}
```

**Behavior:**
- Wrapped in a database transaction — all-or-nothing
- Spans reference their parent via `parent_span_external_id` (resolved within the batch)
- If `external_id` already exists for this org, the record is **upserted** (idempotent)
- `trace` is required; `spans` and nested `llm_response` are optional

---

## 5. Error Handling

All error responses follow a consistent format:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Validation failed: Name can't be blank",
    "details": { "name": ["can't be blank"] }
  }
}
```

| HTTP Status | Code | When |
|---|---|---|
| 401 | `unauthorized` | Missing or invalid API key |
| 403 | `forbidden` | API key is revoked |
| 422 | `validation_failed` | Invalid params / failed model validations |
| 409 | `conflict` | Duplicate `external_id` (when not using upsert) |
| 500 | `internal_error` | Unexpected server error |

---

## 6. Implementation Plan

### Phase 1: Foundation
1. **Migration: `CreateMonitoringApiKeys`** — New table with token digest, org FK, status
2. **Model: `MonitoringApiKey`** — Token generation, hashing, `acts_as_tenant`
3. **Controller: `Api::V1::BaseController`** — Bearer auth, tenant resolution, JSON error handling
4. **Routes** — `/api/v1/monitoring/*`

### Phase 2: Schema Changes
5. **Migration: Add `external_id` columns** to traces, spans, llm_responses (unique per org)
6. **Migration: Make `agent_version_id` and `rendered_prompt` nullable** on llm_responses
7. **Migration: Add `llm_response_id`** to spans (optional FK)

### Phase 3: Individual Resource Endpoints
8. **Controller: `Api::V1::Monitoring::TracesController`** — create action
9. **Controller: `Api::V1::Monitoring::SpansController`** — create action
10. **Controller: `Api::V1::Monitoring::LlmResponsesController`** — create action

### Phase 4: Batch Ingest
11. **Service: `Monitoring::IngestService`** — Orchestrates trace+spans+llm_responses in a transaction
12. **Controller: `Api::V1::Monitoring::IngestController`** — Delegates to service

### Phase 5: API Key Management UI
13. **Controller: Organization Settings section** for creating/revoking monitoring API keys
14. **Views** — List keys, create key (show token once), revoke key

### Phase 6: Testing
15. **Request specs** for each endpoint (auth, success, validation errors, idempotency)
16. **Model specs** for `MonitoringApiKey`
17. **Service specs** for `Monitoring::IngestService`

---

## 7. Security Considerations

- **Token hashing**: Raw tokens are never stored. We store `SHA-256(token)` and compare on lookup. The raw token is shown to the user exactly once at creation.
- **No session auth on API routes**: `Api::V1::BaseController` inherits from `ActionController::API` (no cookies, no CSRF).
- **Tenant isolation**: Every API request resolves the org from the API key. All queries are scoped via `acts_as_tenant`.
- **Key revocation**: Revoked keys immediately return 403. No grace period.
- **No sensitive data in responses**: API responses return only IDs and timestamps, never prompt content.

---

## 8. Future Considerations (Post-v1)

- **Read APIs** — `GET /api/v1/monitoring/traces/:id` for SDK-side verification
- **Update endpoints** — `PATCH /api/v1/monitoring/traces/:id` to close running traces
- **Rate limiting** — Per-key rate limits via `Rack::Attack`
- **Async ingestion** — Queue writes via Sidekiq for high-throughput scenarios
- **SDK gems/packages** — Ruby, Python, JavaScript SDKs wrapping the API
- **Streaming/SSE** — Real-time trace streaming for live debugging
- **Scoped API keys** — Keys with limited permissions (e.g., write-only monitoring)
