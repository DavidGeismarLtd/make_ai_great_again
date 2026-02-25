# Architecture Overview
## MakeAiGreatAgain - PromptTracker Platform

**Version:** 1.0
**Date:** 2026-02-24
**Related Documents**: [PRD.md](./PRD.md), [DATABASE_SCHEMA.md](./DATABASE_SCHEMA.md)

---

## System Architecture

### High-Level Overview

MakeAiGreatAgain is a **two-tier architecture** consisting of:

1. **Host Application** (this repository) - Handles authentication, multi-tenancy, and configuration
2. **PromptTracker Engine** (separate gem) - Provides core prompt management and LLM tracking features

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                      │
│  (Bootstrap 5 + Hotwire: Turbo + Stimulus)                  │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│              Host Application (MakeAiGreatAgain)             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Authentication│  │Authorization │  │Multi-Tenancy │      │
│  │   (Devise)   │  │   (Pundit)   │  │(Organizations)│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  API Keys    │  │Landing Pages │  │  Onboarding  │      │
│  │  Management  │  │  & Marketing │  │     Flow     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│              PromptTracker Engine (Gem)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Prompts    │  │ LLM Tracking │  │  Evaluation  │      │
│  │  Management  │  │  & Logging   │  │    System    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  A/B Testing │  │   Datasets   │  │  Analytics   │      │
│  │ (Experiments)│  │   & Tests    │  │  Dashboard   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    Data & Services Layer                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  PostgreSQL  │  │    Redis     │  │   Sidekiq    │      │
│  │   Database   │  │Cache & Queue │  │Background Jobs│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   OpenAI     │  │  Anthropic   │  │    Google    │      │
│  │     API      │  │     API      │  │  Gemini API  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────┐                                           │
│  │Email Service │                                           │
│  │(SendGrid/SES)│                                           │
│  └──────────────┘                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## Component Responsibilities

### Host Application (MakeAiGreatAgain)

#### 1. Authentication (Devise)
- User registration and login
- Email confirmation
- Password reset
- Account lockout after failed attempts
- Session management

#### 2. Authorization (Pundit)
- Role-based access control (RBAC)
- Organization-level permissions
- Resource-level authorization
- Policy enforcement

#### 3. Multi-Tenancy (acts_as_tenant gem)
- Automatic tenant scoping for all queries
- Organization management
- Team member invitations
- Membership management
- Complete data isolation between organizations
- Thread-safe tenant management
- Sidekiq integration for background jobs
- Fail-safe with `require_tenant` option

#### 4. API Key Management
- Encrypted storage of LLM provider API keys
- Key validation and testing
- Multiple keys per provider
- Key rotation support

#### 5. User Interface
- Landing page and marketing content
- User onboarding flow
- Organization settings
- Navigation and layout

---

### PromptTracker Engine

#### 1. Prompt Management
- Create, edit, delete prompts
- Version control for prompts
- Variable substitution
- Prompt templates

#### 2. LLM Call Tracking
- Log all LLM API calls
- Track tokens, costs, latency
- Store request/response data
- Provider abstraction layer

#### 3. Evaluation System
- Automated response evaluation
- Multiple evaluator types:
  - Length checks
  - Pattern matching
  - LLM-as-judge
  - Custom evaluators
- Scoring and metrics

#### 4. A/B Testing
- Create experiments
- Compare prompt versions
- Statistical analysis
- Winner selection

#### 5. Analytics
- Response quality metrics
- Cost analysis
- Performance monitoring
- Usage statistics

---

## Data Flow

### 1. User Registration Flow

```
User → Host App → PostgreSQL
  ↓
Email Service → User
  ↓
User → Host App → PostgreSQL (confirm)
```

### 2. Organization Setup Flow

```
User → Host App → Create Organization → PostgreSQL
  ↓
Create Membership (Owner) → PostgreSQL
  ↓
Configure API Keys → Encrypt → PostgreSQL
```

### 3. Prompt Execution Flow

```
User → PromptTracker Engine
  ↓
Check Authorization → Host App (Pundit)
  ↓
Get API Key → Host App → Decrypt → Return Key
  ↓
Render Prompt with Variables
  ↓
Call LLM Provider API (OpenAI/Anthropic/Google)
  ↓
Receive Response
  ↓
Log to PostgreSQL (with organization_id)
  ↓
Queue Evaluation Job → Sidekiq → Redis
  ↓
Return Response to User
```

### 4. Background Evaluation Flow

```
Sidekiq Worker → Fetch LLM Response
  ↓
Run Evaluators (length, pattern, LLM-as-judge)
  ↓
Calculate Scores
  ↓
Save Results → PostgreSQL
  ↓
Update Analytics Dashboard
```

---

## Security Architecture

### 1. Authentication Security
- Bcrypt password hashing
- Email confirmation required
- Account lockout after 5 failed attempts
- Session timeout after 2 weeks
- Secure password reset tokens (2-hour expiry)

### 2. Authorization Security
- Pundit policies enforce permissions
- All resources scoped by organization
- Row-level security via organization_id
- No cross-organization data access

### 3. API Key Security
- Rails ActiveRecord encryption at rest
- Encryption keys stored in Rails credentials
- Never display full keys (only last 4 chars)
- HTTPS-only transmission
- Audit logging for all key operations

### 4. Application Security
- HTTPS enforced (redirect HTTP)
- Secure headers (CSP, HSTS, X-Frame-Options)
- CSRF protection (Rails default)
- SQL injection prevention (parameterized queries)
- XSS prevention (sanitized output)
- Rate limiting on auth endpoints

---

## Scalability Considerations

### Horizontal Scaling
- Stateless application servers
- Session storage in database or Redis
- Load balancer ready
- No server-side state

### Database Optimization
- Proper indexing on foreign keys
- Composite indexes for common queries
- Connection pooling
- Query optimization (N+1 prevention)

### Caching Strategy
- Redis for session storage
- HTTP caching headers
- Fragment caching for expensive views
- Database query caching

### Background Jobs
- Sidekiq for async processing
- Separate queues for different priorities
- Job retry logic
- Dead letter queue for failed jobs

---

## Deployment Architecture

### Development Environment
```
Local Machine
├── Rails Server (port 3000)
├── PostgreSQL (port 5432)
├── Redis (port 6379)
└── Sidekiq Worker
```

### Production Environment (Kamal)
```
Docker Host
├── Web Container (Rails + Puma)
├── Worker Container (Sidekiq)
├── PostgreSQL (managed service)
├── Redis (managed service)
└── Load Balancer (Thruster)
```

---

## Integration Points

### Host App ↔ PromptTracker Engine

#### 1. Authentication Context
```ruby
# Engine controllers inherit from host app
class PromptTracker::ApplicationController < ::ApplicationController
  before_action :authenticate_user!
  before_action :set_current_organization
end
```

#### 2. API Key Resolution
```ruby
# Host app provides API keys to engine
PromptTracker.configure do |config|
  config.api_key_resolver = ->(organization, provider) {
    organization.api_configurations
      .active
      .find_by(provider: provider)
      &.decrypted_api_key
  }
end
```

#### 3. Organization Scoping
```ruby
# All engine models scoped by organization
class PromptTracker::Prompt < ApplicationRecord
  belongs_to :organization

  scope :for_organization, ->(org) { where(organization: org) }
end
```

---

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Bootstrap 5 | UI framework |
| | Hotwire (Turbo + Stimulus) | JavaScript framework |
| | Importmap | JavaScript module management |
| **Backend** | Ruby 3.3.5 | Programming language |
| | Rails 8.1.2 | Web framework |
| | Devise | Authentication |
| | Pundit | Authorization |
| | acts_as_tenant | Multi-tenancy |
| **Database** | PostgreSQL 16+ | Primary database |
| | Redis 7+ | Cache & job queue |
| **Background** | Sidekiq | Job processing |
| **Testing** | RSpec | Test framework |
| | FactoryBot | Test fixtures |
| | Capybara | System tests |
| **Deployment** | Kamal | Docker deployment |
| | Docker | Containerization |
| **CI/CD** | GitHub Actions | Continuous integration |

---

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Page Load Time | <2s | 95th percentile |
| API Response Time | <500ms | 95th percentile |
| Database Query Time | <100ms | 95th percentile |
| Background Job Processing | <5s | Average |
| Concurrent Users | 1000+ | Load testing |
| Uptime | 99.9% | Monthly |

---

## Monitoring & Observability

### Application Monitoring
- Error tracking (Sentry/Rollbar)
- Performance monitoring (APM)
- Log aggregation
- Health check endpoints

### Database Monitoring
- Query performance
- Connection pool usage
- Slow query log
- Database size and growth

### Infrastructure Monitoring
- Server resources (CPU, memory, disk)
- Network traffic
- Container health
- Service availability

---

**Last Updated**: 2026-02-24
