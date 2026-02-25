# Database Schema
## MakeAiGreatAgain - PromptTracker Platform

**Version:** 1.0  
**Date:** 2026-02-24  
**Database**: PostgreSQL 16+

---

## Entity Relationship Diagram

```
┌─────────────────┐
│     Users       │
├─────────────────┤
│ id              │◄──┐
│ email           │   │
│ encrypted_pwd   │   │
│ first_name      │   │
│ last_name       │   │
│ role            │   │
│ confirmed_at    │   │
│ locked_at       │   │
└─────────────────┘   │
         │            │
         │            │
         ▼            │
┌─────────────────────────────┐
│ OrganizationMemberships     │
├─────────────────────────────┤
│ id                          │
│ organization_id (FK)        │
│ user_id (FK)                │
│ role (viewer/member/admin)  │
└─────────────────────────────┘
         │
         │
         ▼
┌─────────────────┐
│ Organizations   │
├─────────────────┤
│ id              │
│ name            │
│ slug (unique)   │
│ plan            │
│ status          │
│ owner_id (FK)   │──┘
└─────────────────┘
         │
         │
         ▼
┌─────────────────────┐
│ ApiConfigurations   │
├─────────────────────┤
│ id                  │
│ organization_id(FK) │
│ provider            │
│ key_name            │
│ encrypted_api_key   │
│ is_active           │
│ last_validated_at   │
└─────────────────────┘
```

---

## Table Definitions

### users

Stores user account information with Devise authentication.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| email | string | NOT NULL, UNIQUE | User email address |
| encrypted_password | string | NOT NULL | Bcrypt encrypted password |
| reset_password_token | string | UNIQUE | Token for password reset |
| reset_password_sent_at | datetime | | When reset token was sent |
| remember_created_at | datetime | | Remember me token timestamp |
| sign_in_count | integer | DEFAULT 0 | Number of sign-ins |
| current_sign_in_at | datetime | | Current sign-in timestamp |
| last_sign_in_at | datetime | | Previous sign-in timestamp |
| current_sign_in_ip | string | | Current sign-in IP address |
| last_sign_in_ip | string | | Previous sign-in IP address |
| confirmation_token | string | UNIQUE | Email confirmation token |
| confirmed_at | datetime | | Email confirmation timestamp |
| confirmation_sent_at | datetime | | When confirmation email sent |
| unconfirmed_email | string | | New email pending confirmation |
| failed_attempts | integer | DEFAULT 0 | Failed login attempts |
| unlock_token | string | UNIQUE | Account unlock token |
| locked_at | datetime | | Account lock timestamp |
| first_name | string | NOT NULL | User's first name |
| last_name | string | NOT NULL | User's last name |
| role | string | DEFAULT 'member' | User role (member/admin/super_admin) |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_users_on_email` (unique)
- `index_users_on_reset_password_token` (unique)
- `index_users_on_confirmation_token` (unique)
- `index_users_on_unlock_token` (unique)

---

### organizations

Stores organization/workspace information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| name | string | NOT NULL | Organization name |
| slug | string | NOT NULL, UNIQUE | URL-friendly identifier |
| plan | string | NOT NULL, DEFAULT 'free' | Subscription plan |
| status | string | NOT NULL, DEFAULT 'active' | Organization status |
| owner_id | bigint | NOT NULL, FK → users.id | Organization owner |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_organizations_on_slug` (unique)
- `index_organizations_on_owner_id`

**Enums:**
- `plan`: free, starter, professional, enterprise
- `status`: active, suspended, cancelled

---

### organization_memberships

Join table linking users to organizations with roles.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| organization_id | bigint | NOT NULL, FK → organizations.id | Organization reference |
| user_id | bigint | NOT NULL, FK → users.id | User reference |
| role | string | NOT NULL, DEFAULT 'member' | Member role |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_organization_memberships_on_organization_id`
- `index_organization_memberships_on_user_id`
- `index_organization_memberships_on_organization_id_and_user_id` (unique)

**Enums:**
- `role`: viewer, member, admin, owner

**Constraints:**
- Unique combination of (organization_id, user_id)

---

### api_configurations

Stores encrypted API keys for LLM providers per organization.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | bigint | PK | Primary key |
| organization_id | bigint | NOT NULL, FK → organizations.id | Organization reference |
| provider | string | NOT NULL | LLM provider name |
| key_name | string | NOT NULL | User-friendly key label |
| encrypted_api_key | text | | Encrypted API key (Rails encryption) |
| is_active | boolean | DEFAULT true | Whether key is active |
| last_validated_at | datetime | | Last successful validation |
| created_at | datetime | NOT NULL | Record creation timestamp |
| updated_at | datetime | NOT NULL | Record update timestamp |

**Indexes:**
- `index_api_configurations_on_organization_id`
- `index_api_configs_on_org_provider_name` (unique on organization_id, provider, key_name)

**Enums:**
- `provider`: openai, anthropic, google, azure_openai

**Constraints:**
- Unique combination of (organization_id, provider, key_name)

**Encryption:**
- `encrypted_api_key` is encrypted using Rails ActiveRecord encryption
- Encryption keys stored in Rails credentials (not in database)

---

## PromptTracker Engine Tables

The following tables are managed by the PromptTracker engine and will be extended with `organization_id` for multi-tenancy:

### prompt_tracker_prompts
- Stores prompt templates with variables
- **Extension**: Add `organization_id` column

### prompt_tracker_prompt_versions
- Version history for prompts
- Inherits organization scope from parent prompt

### prompt_tracker_llm_responses
- Logged LLM API responses
- Inherits organization scope from parent prompt

### prompt_tracker_evaluations
- Evaluation results for responses
- Inherits organization scope from parent response

### prompt_tracker_experiments
- A/B test configurations
- **Extension**: Add `organization_id` column

### prompt_tracker_datasets
- Test datasets for prompts
- **Extension**: Add `organization_id` column

---

## Data Isolation Strategy

### Multi-Tenancy Implementation

All PromptTracker resources are scoped to organizations:

```ruby
# Example scoping in controllers
class PromptsController < ApplicationController
  before_action :set_organization

  def index
    @prompts = @organization.prompts
  end

  private

  def set_organization
    @organization = current_user.organizations.find_by!(slug: params[:org_slug])
  end
end
```

### Security Considerations

1. **Row-Level Security**: All queries filtered by organization_id
2. **Policy Enforcement**: Pundit policies check organization membership
3. **API Key Isolation**: Keys never shared between organizations
4. **Audit Logging**: All data access logged with organization context

---

## Migrations Checklist

### Phase 1 Migrations
- [ ] Create users table (Devise)
- [ ] Create organizations table
- [ ] Create organization_memberships table
- [ ] Create api_configurations table

### Phase 2 Migrations (PromptTracker Integration)
- [ ] Add organization_id to prompt_tracker_prompts
- [ ] Add organization_id to prompt_tracker_experiments
- [ ] Add organization_id to prompt_tracker_datasets
- [ ] Add indexes for organization_id columns
- [ ] Add foreign key constraints

---

**Last Updated**: 2026-02-24

