# Product Requirements Document (PRD)
## MakeAiGreatAgain - PromptTracker Platform

**Version:** 1.0
**Date:** 2026-02-24
**Status:** Draft
**Owner:** David Geismar

---

## 1. Executive Summary

### 1.1 Product Vision
MakeAiGreatAgain is a multi-tenant SaaS platform that provides enterprise-grade prompt management and LLM tracking capabilities through the PromptTracker engine. The platform enables companies and individuals to manage, version, test, and analyze their LLM prompts with comprehensive analytics and evaluation tools.

### 1.2 Core Value Proposition
- **For Companies**: Centralized prompt management with team collaboration, access control, and secure API key management
- **For Individuals**: Professional-grade prompt engineering tools with analytics and A/B testing capabilities
- **For Teams**: Multi-user access with role-based permissions and shared prompt libraries

### 1.3 Product Scope
This application serves as the **wrapper/host application** for the PromptTracker engine, handling:
- User authentication and account management
- Multi-tenancy (organizations/teams)
- Access control and authorization
- Secure API key configuration and storage
- Marketing landing page and onboarding
- Billing and subscription management (future)

The **PromptTracker engine** (separate gem) provides:
- Prompt creation, versioning, and management
- LLM call tracking and logging
- Response evaluation and scoring
- A/B testing and experiments
- Analytics dashboard
- Dataset management and testing

---

## 2. Technical Architecture

### 2.1 Technology Stack

#### Backend
- **Framework**: Ruby on Rails 8.1.2
- **Ruby Version**: 3.3.5
- **Database**: PostgreSQL (required by PromptTracker)
- **Background Jobs**: Sidekiq + Redis (required by PromptTracker)
- **Cache**: Redis (shared with Sidekiq)
- **Authentication**: Devise (recommended)
- **Authorization**: Pundit
- **Multi-Tenancy**: acts_as_tenant gem
- **API Key Encryption**: Rails encrypted credentials + ActiveRecord encryption

#### Frontend
- **CSS Framework**: Bootstrap 5 (matching PromptTracker engine)
- **JavaScript**: Hotwire (Turbo + Stimulus)
- **Asset Pipeline**: Propshaft
- **Module System**: Importmap

#### Testing
- **Framework**: RSpec
- **Factories**: FactoryBot
- **Fake Data**: Faker
- **Matchers**: Shoulda Matchers
- **Coverage**: SimpleCov
- **System Tests**: Capybara + Selenium

#### DevOps
- **Containerization**: Docker + Docker Compose
- **Deployment**: Kamal
- **CI/CD**: GitHub Actions
- **Monitoring**: TBD (Sentry, Rollbar, or similar)

### 2.2 Database Architecture

#### Core Tables (Host Application)
```
users
  - id
  - email (unique, encrypted)
  - encrypted_password
  - first_name
  - last_name
  - role (enum: admin, member, viewer)
  - organization_id (foreign key)
  - confirmed_at
  - current_sign_in_at
  - timestamps

organizations
  - id
  - name
  - slug (unique)
  - plan (enum: free, starter, professional, enterprise)
  - status (enum: active, suspended, cancelled)
  - owner_id (foreign key to users)
  - timestamps

organization_memberships
  - id
  - organization_id
  - user_id
  - role (enum: owner, admin, member, viewer)
  - timestamps
  - unique index on [organization_id, user_id]

api_configurations
  - id
  - organization_id
  - provider (enum: openai, anthropic, google, etc.)
  - encrypted_api_key
  - encrypted_api_key_iv
  - key_name (e.g., "Production OpenAI", "Development Anthropic")
  - is_active (boolean)
  - last_validated_at
  - timestamps
```

#### PromptTracker Tables (from engine)
- prompts
- prompt_versions
- llm_responses
- evaluations
- experiments
- datasets
- test_runs
- (see PromptTracker gem for complete schema)

---

## 3. Feature Requirements

### 3.1 Landing Page & Marketing

#### 3.1.1 Public Landing Page
**Priority**: P0 (Must Have)

**User Story**: As a visitor, I want to understand what PromptTracker offers so I can decide if it's right for me.

**Requirements**:
- Hero section with clear value proposition
- Feature highlights:
  - Prompt versioning and management
  - LLM call tracking and analytics
  - Automated evaluation and testing
  - A/B testing capabilities
  - Multi-provider support (OpenAI, Anthropic, Google)
- Use cases section (for developers, teams, enterprises)
- Pricing tiers (if applicable)
- Call-to-action buttons (Sign Up, Request Demo)
- Responsive design (mobile, tablet, desktop)
- Fast load times (<2s)

**Design Consistency**:
- Use Bootstrap 5 (same as PromptTracker engine)
- Match color scheme and typography from PromptTracker
- Consistent navigation and branding

#### 3.1.2 About/How It Works Page
**Priority**: P1 (Should Have)

**Requirements**:
- Detailed explanation of PromptTracker features
- Architecture diagram showing how the platform works
- Integration examples and code snippets
- Screenshots/demos of the UI
- FAQ section

---

### 3.2 Authentication & User Management

#### 3.2.1 User Registration
**Priority**: P0 (Must Have)

**User Story**: As a new user, I want to create an account so I can access PromptTracker features.

**Requirements**:
- Email + password registration
- Email confirmation required
- Password strength requirements (min 8 chars, uppercase, lowercase, number)
- Terms of Service and Privacy Policy acceptance
- Optional: Social login (Google, GitHub) - P2
- Redirect to onboarding flow after registration

**Validations**:
- Email format validation
- Email uniqueness check
- Password confirmation match
- Prevent disposable email addresses (optional)

#### 3.2.2 User Login/Logout
**Priority**: P0 (Must Have)

**Requirements**:
- Email + password login
- "Remember me" checkbox (30-day session)
- Password reset via email
- Account lockout after 5 failed attempts (15-minute cooldown)
- Session timeout after 2 weeks of inactivity
- Secure logout (clear all sessions)

#### 3.2.3 User Profile Management
**Priority**: P0 (Must Have)

**User Story**: As a user, I want to manage my profile information.

**Requirements**:
- View/edit profile:
  - First name, last name
  - Email (requires re-confirmation)
  - Password change (requires current password)
  - Avatar upload (optional - P2)
- Account deletion (with confirmation)
- Activity log (login history, API usage)

#### 3.2.4 Password Reset
**Priority**: P0 (Must Have)

**Requirements**:
- "Forgot password" link on login page
- Email with secure reset token (expires in 2 hours)
- Reset password form with confirmation
- Invalidate all existing sessions on password change
- Email notification of password change

---

### 3.3 Organization/Team Management

#### 3.3.1 Organization Creation
**Priority**: P0 (Must Have)

**User Story**: As a user, I want to create an organization so my team can collaborate.

**Requirements**:
- Create organization during onboarding or from dashboard
- Organization details:
  - Organization name (required)
  - Slug (auto-generated from name, editable, unique)
  - Plan selection (free, starter, professional, enterprise)
- User becomes organization owner automatically
- Personal workspace vs. organization workspace toggle

#### 3.3.2 Team Member Invitation
**Priority**: P0 (Must Have)

**User Story**: As an organization owner/admin, I want to invite team members.

**Requirements**:
- Invite by email
- Assign role during invitation (admin, member, viewer)
- Email invitation with secure token (expires in 7 days)
- Invitee can accept/decline invitation
- Pending invitations list
- Resend invitation option
- Revoke invitation option

#### 3.3.3 Member Management
**Priority**: P0 (Must Have)

**User Story**: As an organization owner/admin, I want to manage team members.

**Requirements**:
- View all members with roles
- Change member roles (owner, admin, member, viewer)
- Remove members (with confirmation)
- Transfer ownership (requires confirmation from new owner)
- View member activity (last login, API usage)

#### 3.3.4 Organization Settings
**Priority**: P1 (Should Have)

**Requirements**:
- Edit organization name and slug
- Organization logo upload
- Billing information (future)
- Danger zone: Delete organization (requires confirmation + password)

---

### 3.4 Access Control & Authorization

#### 3.4.1 Role-Based Access Control (RBAC)
**Priority**: P0 (Must Have)

**Roles & Permissions**:

| Feature | Viewer | Member | Admin | Owner |
|---------|--------|--------|-------|-------|
| View prompts | ✓ | ✓ | ✓ | ✓ |
| Create prompts | ✗ | ✓ | ✓ | ✓ |
| Edit prompts | ✗ | ✓ | ✓ | ✓ |
| Delete prompts | ✗ | ✗ | ✓ | ✓ |
| View analytics | ✓ | ✓ | ✓ | ✓ |
| Run experiments | ✗ | ✓ | ✓ | ✓ |
| Manage API keys | ✗ | ✗ | ✓ | ✓ |
| Invite members | ✗ | ✗ | ✓ | ✓ |
| Manage members | ✗ | ✗ | ✓ | ✓ |
| Change roles | ✗ | ✗ | ✗ | ✓ |
| Billing settings | ✗ | ✗ | ✗ | ✓ |
| Delete organization | ✗ | ✗ | ✗ | ✓ |

**Implementation**:
- Use Pundit for authorization policies
- Scope all PromptTracker resources by organization
- Enforce permissions at controller and view levels
- API endpoints respect same permissions

#### 3.4.2 Multi-Tenancy
**Priority**: P0 (Must Have)

**Requirements**:
- Use `acts_as_tenant` gem for automatic tenant scoping
- Complete data isolation between organizations
- All PromptTracker resources scoped to organization
- User can belong to multiple organizations
- Organization switcher in navigation
- Default organization preference per user
- URL structure: `/orgs/:org_slug/prompts` or subdomain (future)
- Thread-safe tenant management
- Sidekiq integration for background jobs

**Implementation with acts_as_tenant**:
```ruby
# Gemfile
gem 'acts_as_tenant'

# config/initializers/acts_as_tenant.rb
ActsAsTenant.configure do |config|
  config.require_tenant = true  # Raise error if tenant not set
  config.job_scope = ->{ where(status: :active) }
end

# Enable Sidekiq integration
require 'acts_as_tenant/sidekiq'

# ApplicationController
class ApplicationController < ActionController::Base
  set_current_tenant_through_filter
  before_action :set_current_tenant

  private

  def set_current_tenant
    return unless user_signed_in?

    organization = if params[:organization_id]
      current_user.organizations.find(params[:organization_id])
    else
      current_user.organizations.first
    end

    ActsAsTenant.current_tenant = organization
  end
end

# Models with tenant scoping
class ApiConfiguration < ApplicationRecord
  acts_as_tenant :organization
  # Automatically adds:
  # - belongs_to :organization
  # - default_scope for current tenant
  # - validation to prevent cross-tenant associations
end

# PromptTracker engine models
class PromptTracker::Prompt < ApplicationRecord
  acts_as_tenant :organization
end

class PromptTracker::LlmCall < ApplicationRecord
  acts_as_tenant :organization
end

# Background jobs (tenant automatically set)
class EvaluationJob
  include Sidekiq::Job

  def perform(llm_call_id)
    # Tenant is automatically set from job arguments
    llm_call = LlmCall.find(llm_call_id)
    # ... evaluation logic
  end
end

# Manual tenant switching (for admin operations)
ActsAsTenant.with_tenant(organization) do
  Prompt.all  # Only prompts for this organization
end

# Disable tenant checking (for admin dashboards)
ActsAsTenant.without_tenant do
  Organization.all  # All organizations
end
```

**Benefits**:
- Automatic scoping of all queries to current tenant
- Thread-safe tenant management
- Built-in Sidekiq integration
- Prevents accidental cross-tenant data access
- Validates tenant associations on save
- Supports `validates_uniqueness_to_tenant` for scoped uniqueness
- Fail-safe with `require_tenant` option

---

### 3.5 API Key Configuration & Management

#### 3.5.1 API Key Storage
**Priority**: P0 (Must Have)

**User Story**: As an admin, I want to securely store API keys for LLM providers.

**Requirements**:
- Support multiple providers:
  - OpenAI
  - Anthropic
  - Google (Gemini)
  - Azure OpenAI (future)
  - Custom endpoints (future)
- Multiple keys per provider (e.g., "Production", "Development", "Testing")
- Encryption at rest using Rails ActiveRecord encryption
- Encryption in transit (HTTPS only)
- Never display full API key after creation (show last 4 chars only)
- Key validation on save (test API call to provider)

**Security Requirements**:
- Use Rails 7+ encryption with key rotation support
- Store encryption keys in Rails credentials (not in database)
- Audit log for all API key operations (create, update, delete, access)
- Optional: Key expiration dates
- Optional: IP whitelist for API key usage

#### 3.5.2 API Key Management UI
**Priority**: P0 (Must Have)

**Requirements**:
- List all configured API keys:
  - Provider name
  - Key name/label
  - Last 4 characters of key
  - Status (active/inactive)
  - Last validated date
  - Created date
- Add new API key:
  - Select provider
  - Enter key name/label
  - Paste API key
  - Test connection button
  - Set as active/default
- Edit API key:
  - Update key name/label
  - Rotate key (enter new key)
  - Toggle active status
- Delete API key (with confirmation)
- Set default key per provider

#### 3.5.3 PromptTracker Integration
**Priority**: P0 (Must Have)

**User Story**: As a developer, I want PromptTracker to use my organization's API keys automatically.

**Requirements**:
- PromptTracker engine reads API keys from database (not .env file)
- API key resolution logic:
  1. Use organization's active key for the provider
  2. Fall back to system default (if configured)
  3. Return error if no key available
- Pass organization context to PromptTracker engine
- PromptTracker respects organization boundaries
- API key rotation doesn't break existing functionality

**Implementation Approach**:
```ruby
# In host application
PromptTracker.configure do |config|
  config.api_key_resolver = ->(organization, provider) {
    organization.api_configurations
      .active
      .find_by(provider: provider)
      &.decrypted_api_key
  }
end
```

---

### 3.6 PromptTracker Engine Integration

#### 3.6.1 Engine Mounting
**Priority**: P0 (Must Have)

**Requirements**:
- Mount PromptTracker engine at `/app` or `/prompts`
- All engine routes scoped under organization: `/orgs/:org_slug/app`
- Engine inherits authentication from host app
- Engine respects organization context
- Shared navigation between host app and engine

#### 3.6.2 Design Consistency
**Priority**: P0 (Must Have)

**Requirements**:
- Host app uses same Bootstrap 5 version as engine
- Shared layout template with:
  - Common header/navigation
  - Organization switcher
  - User menu
  - Breadcrumbs
- Consistent color scheme and typography
- Shared CSS variables for theming
- Responsive design matching engine

#### 3.6.3 Data Scoping
**Priority**: P0 (Must Have)

**Requirements**:
- All PromptTracker models scoped to organization
- Add `organization_id` to PromptTracker tables via migration
- Override PromptTracker controllers to enforce scoping
- Prevent cross-organization data access
- Audit trail for all data access

---

### 3.7 Onboarding Flow

#### 3.7.1 New User Onboarding
**Priority**: P1 (Should Have)

**User Story**: As a new user, I want guided setup so I can start using PromptTracker quickly.

**Steps**:
1. **Welcome Screen**: Brief intro to PromptTracker
2. **Create Organization**: Name your workspace
3. **Configure API Keys**: Add at least one LLM provider key
4. **Create First Prompt**: Guided prompt creation
5. **Invite Team** (optional): Invite collaborators
6. **Complete**: Redirect to dashboard

**Requirements**:
- Progress indicator (step 1 of 5)
- Skip option for optional steps
- Save progress (can resume later)
- Dismissible (can access from settings later)

---

## 4. Non-Functional Requirements

### 4.1 Performance
- Page load time: <2 seconds (95th percentile)
- API response time: <500ms (95th percentile)
- Support 1000+ concurrent users
- Database query optimization (N+1 prevention)
- Asset optimization (minification, compression)

### 4.2 Security
- HTTPS only (redirect HTTP to HTTPS)
- Secure headers (CSP, HSTS, X-Frame-Options)
- SQL injection prevention (parameterized queries)
- XSS prevention (sanitize user input)
- CSRF protection (Rails default)
- Rate limiting on authentication endpoints
- API key encryption at rest and in transit
- Regular security audits (Brakeman, Bundler Audit)
- Dependency updates (Dependabot)

### 4.3 Scalability
- Horizontal scaling support (stateless app servers)
- Database connection pooling
- Background job processing (Sidekiq)
- Caching strategy (Redis, HTTP caching)
- CDN for static assets (future)

### 4.4 Reliability
- 99.9% uptime SLA (future)
- Automated backups (daily database backups)
- Disaster recovery plan
- Error tracking and monitoring (Sentry/Rollbar)
- Health check endpoints

### 4.5 Maintainability
- Comprehensive test coverage (>80%)
- Code style enforcement (RuboCop)
- Documentation (inline comments, README, API docs)
- Changelog maintenance
- Semantic versioning

---

## 5. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
**Goal**: Set up core infrastructure and authentication

**Tasks**:
- [ ] Switch from SQLite to PostgreSQL
- [ ] Install and configure RSpec
- [ ] Install and configure Bootstrap 5
- [ ] Set up Devise for authentication
- [ ] Set up Pundit for authorization
- [ ] Create User model and authentication flows
- [ ] Create Organization model
- [ ] Create OrganizationMembership model
- [ ] Implement basic RBAC
- [ ] Set up CI/CD pipeline updates

**Deliverables**:
- Users can register, login, logout
- Users can create organizations
- Basic role-based access control
- Test suite running in CI

### Phase 2: PromptTracker Integration (Weeks 3-4)
**Goal**: Integrate PromptTracker engine with multi-tenancy

**Tasks**:
- [ ] Install PromptTracker gem
- [ ] Add organization_id to PromptTracker tables
- [ ] Mount engine with organization scoping
- [ ] Configure shared layout and navigation
- [ ] Implement API key configuration model
- [ ] Build API key management UI
- [ ] Integrate API keys with PromptTracker
- [ ] Test multi-tenancy isolation

**Deliverables**:
- PromptTracker engine accessible per organization
- API keys stored securely and used by engine
- Complete data isolation between organizations
- Consistent UI/UX across host app and engine

### Phase 3: Team Collaboration (Week 5)
**Goal**: Enable team collaboration features

**Tasks**:
- [ ] Implement team member invitation system
- [ ] Build member management UI
- [ ] Implement role-based permissions in PromptTracker
- [ ] Add organization switcher
- [ ] Build activity logs
- [ ] Add email notifications

**Deliverables**:
- Users can invite team members
- Admins can manage member roles
- Users can switch between organizations
- Email notifications for invitations and key events

### Phase 4: Landing Page & Onboarding (Week 6)
**Goal**: Create public-facing pages and onboarding

**Tasks**:
- [ ] Design and build landing page
- [ ] Create about/how-it-works page
- [ ] Build onboarding flow
- [ ] Add documentation pages
- [ ] Implement FAQ section
- [ ] SEO optimization

**Deliverables**:
- Professional landing page
- Guided onboarding for new users
- Public documentation

### Phase 5: Polish & Launch Prep (Week 7-8)
**Goal**: Production readiness

**Tasks**:
- [ ] Security audit and fixes
- [ ] Performance optimization
- [ ] Error handling and user feedback
- [ ] Email templates design
- [ ] Monitoring and alerting setup
- [ ] Backup and recovery testing
- [ ] Load testing
- [ ] Documentation completion
- [ ] Beta user testing

**Deliverables**:
- Production-ready application
- Comprehensive documentation
- Monitoring and alerting in place
- Beta feedback incorporated

---

## 6. Success Metrics

### 6.1 User Acquisition
- 100 registered users in first month
- 20 active organizations in first month
- 50% conversion from visitor to signup

### 6.2 User Engagement
- 70% of users complete onboarding
- 60% of users configure at least one API key
- 50% of users create at least one prompt
- Average 3 sessions per week per active user

### 6.3 Technical Metrics
- <2s average page load time
- >99% uptime
- <1% error rate
- >80% test coverage

### 6.4 Security Metrics
- Zero security incidents
- Zero data breaches
- 100% of API keys encrypted
- All security scans passing

---

## 7. Future Enhancements (Post-MVP)

### 7.1 Billing & Subscriptions (Phase 6)
- Stripe integration
- Subscription plans (Free, Starter, Pro, Enterprise)
- Usage-based billing
- Invoice generation
- Payment method management

### 7.2 Advanced Features (Phase 7+)
- SSO/SAML integration for enterprise
- Audit logs and compliance reports
- Custom roles and permissions
- API access tokens for programmatic access
- Webhooks for integrations
- Slack/Discord notifications
- Advanced analytics and reporting
- White-label options for enterprise

### 7.3 Platform Enhancements
- Mobile app (iOS/Android)
- Browser extension
- VS Code extension
- CLI tool
- Terraform/IaC integration

---

## 8. Risks & Mitigations

### 8.1 Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| PromptTracker engine compatibility issues | High | Medium | Thorough testing, maintain close communication with engine maintainer |
| Database migration from SQLite to PostgreSQL | Medium | Low | Comprehensive backup, test migration in staging |
| API key encryption vulnerabilities | High | Low | Use Rails built-in encryption, security audit, penetration testing |
| Multi-tenancy data leakage | High | Medium | Comprehensive testing, automated tests for data isolation |
| Performance issues with large datasets | Medium | Medium | Database indexing, query optimization, caching strategy |

### 8.2 Business Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Low user adoption | High | Medium | Strong marketing, clear value proposition, free tier |
| Competition from existing tools | Medium | High | Differentiate with superior UX, PromptTracker features |
| API provider rate limits/costs | Medium | Medium | Implement usage quotas, cost monitoring, alerts |

---

## 9. Dependencies

### 9.1 External Dependencies
- PromptTracker gem (maintained by DavidGeismarLtd)
- LLM provider APIs (OpenAI, Anthropic, Google)
- Email service (SendGrid, Postmark, or AWS SES)
- Hosting infrastructure (AWS, Heroku, or similar)

### 9.2 Internal Dependencies
- Design assets and branding
- Legal documents (Terms of Service, Privacy Policy)
- Email templates
- Documentation content

---

## 10. Open Questions

1. **Pricing Strategy**: What pricing tiers should we offer? Free tier limitations?
2. **Email Service**: Which email service provider should we use?
3. **Hosting**: Where should we deploy? (AWS, Heroku, Render, Fly.io?)
4. **Domain**: What domain name? (makeaigreatagain.com, prompttracker.io?)
5. **Branding**: Logo, color scheme, brand guidelines?
6. **Legal**: Do we need legal review for Terms of Service and Privacy Policy?
7. **Analytics**: Which analytics platform? (Google Analytics, Plausible, Fathom?)
8. **Support**: How will we handle customer support? (Intercom, email, Discord?)

---

## 11. Appendices

### 11.1 Glossary
- **Organization**: A workspace that contains users, prompts, and configurations
- **Member**: A user who belongs to an organization
- **Prompt**: A template for LLM interactions with variables
- **Prompt Version**: A specific version of a prompt with change history
- **LLM Response**: A logged response from an LLM API call
- **Evaluation**: An automated assessment of an LLM response
- **Experiment**: An A/B test comparing different prompt versions

### 11.2 References
- PromptTracker GitHub: https://github.com/DavidGeismarLtd/PromptTracker
- Rails 8 Documentation: https://guides.rubyonrails.org/
- Bootstrap 5 Documentation: https://getbootstrap.com/docs/5.3/
- Devise Documentation: https://github.com/heartcombo/devise
- Pundit Documentation: https://github.com/varvet/pundit

---

**Document History**:
- v1.0 (2026-02-24): Initial draft created
