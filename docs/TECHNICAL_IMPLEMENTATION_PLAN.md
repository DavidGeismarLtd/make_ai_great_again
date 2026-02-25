# Technical Implementation Plan
## MakeAiGreatAgain - PromptTracker Platform

**Version:** 1.0
**Date:** 2026-02-24
**Related Document**: [PRD.md](./PRD.md)

---

## Overview

This document provides detailed technical implementation steps for Phase 1 of the MakeAiGreatAgain platform. It serves as a step-by-step guide for developers to set up the foundation infrastructure.

---

## Phase 1: Foundation Setup (Weeks 1-2)

### 1. Database Migration: SQLite → PostgreSQL

#### 1.1 Install PostgreSQL Gem
```ruby
# Gemfile
gem "pg", "~> 1.5"
# Remove: gem "sqlite3", ">= 2.1"
```

#### 1.2 Update database.yml
```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: make_ai_great_again_development

test:
  <<: *default
  database: make_ai_great_again_test

production:
  <<: *default
  database: make_ai_great_again_production
  username: <%= ENV['DATABASE_USERNAME'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>
  host: <%= ENV['DATABASE_HOST'] %>
```

#### 1.3 Create Databases
```bash
bundle install
rails db:create
rails db:migrate
```

---

### 2. RSpec Setup

#### 2.1 Install RSpec Gems
```ruby
# Gemfile
group :development, :test do
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.5"
end

group :test do
  gem "shoulda-matchers", "~> 6.4"
  gem "database_cleaner-active_record", "~> 2.2"
  gem "simplecov", require: false
end
```

#### 2.2 Install RSpec
```bash
bundle install
rails generate rspec:install
```

#### 2.3 Configure RSpec
```ruby
# spec/rails_helper.rb
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
end

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end

# Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
```

#### 2.4 Remove Minitest (Optional)
```bash
rm -rf test/
```

---

### 3. Bootstrap 5 Setup

#### 3.1 Install Bootstrap via Importmap
```bash
bin/importmap pin bootstrap
bin/importmap pin @popperjs/core
```

#### 3.2 Update JavaScript
```javascript
// app/javascript/application.js
import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"
```

#### 3.3 Create Bootstrap SCSS
```scss
// app/assets/stylesheets/application.bootstrap.scss
@import 'bootstrap/scss/bootstrap';

// Custom variables (to match PromptTracker)
$primary: #0d6efd;
$secondary: #6c757d;
$success: #198754;
$info: #0dcaf0;
$warning: #ffc107;
$danger: #dc3545;
```

#### 3.4 Update Application Layout
```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>MakeAiGreatAgain</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body>
    <%= render "shared/navbar" %>

    <main class="container mt-4">
      <%= render "shared/flash" %>
      <%= yield %>
    </main>

    <%= render "shared/footer" %>
  </body>
</html>
```

---

### 4. Devise Setup (Authentication)

#### 4.1 Install Devise
```ruby
# Gemfile
gem "devise", "~> 4.9"
```

```bash
bundle install
rails generate devise:install
rails generate devise User
```

#### 4.2 Configure Devise
```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.mailer_sender = 'noreply@makeaigreatagain.com'
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 2.hours
  config.sign_out_via = :delete
  config.lock_strategy = :failed_attempts
  config.unlock_strategy = :time
  config.maximum_attempts = 5
  config.unlock_in = 15.minutes
end
```

#### 4.3 Customize User Model
```ruby
# db/migrate/XXXXXX_devise_create_users.rb
class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## Database authenticatable
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## Rememberable
      t.datetime :remember_created_at

      ## Trackable
      t.integer  :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip

      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string   :unconfirmed_email

      ## Lockable
      t.integer  :failed_attempts, default: 0, null: false
      t.string   :unlock_token
      t.datetime :locked_at

      ## Custom fields
      t.string :first_name
      t.string :last_name
      t.string :role, default: "member"

      t.timestamps null: false
    end

    add_index :users, :email,                unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :confirmation_token,   unique: true
    add_index :users, :unlock_token,         unique: true
  end
end
```

```ruby
# app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  # Associations
  has_many :organization_memberships, dependent: :destroy
  has_many :organizations, through: :organization_memberships

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true

  # Enums
  enum :role, { member: "member", admin: "admin", super_admin: "super_admin" }

  # Methods
  def full_name
    "#{first_name} #{last_name}"
  end

  def owner_of?(organization)
    organization_memberships.find_by(organization: organization)&.owner?
  end

  def admin_of?(organization)
    membership = organization_memberships.find_by(organization: organization)
    membership&.owner? || membership&.admin?
  end
end
```

#### 4.4 Generate Devise Views
```bash
rails generate devise:views
```

#### 4.5 Update Routes
```ruby
# config/routes.rb
Rails.application.routes.draw do
  devise_for :users

  # Root path
  root "pages#home"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

### 5. Pundit Setup (Authorization)

#### 5.1 Install Pundit
```ruby
# Gemfile
gem "pundit", "~> 2.4"
```

```bash
bundle install
rails generate pundit:install
```

#### 5.2 Configure Application Controller
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
```

#### 5.3 Create Base Policy
```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError
    end

    private

    attr_reader :user, :scope
  end
end
```

---

### 5.4 Install acts_as_tenant (Multi-Tenancy)

#### 5.4.1 Install acts_as_tenant Gem
```ruby
# Gemfile
gem "acts_as_tenant", "~> 1.0"
```

```bash
bundle install
```

#### 5.4.2 Configure acts_as_tenant
```ruby
# config/initializers/acts_as_tenant.rb
ActsAsTenant.configure do |config|
  # Raise error if tenant not set (fail-safe)
  config.require_tenant = true

  # Customize the query for loading the tenant in background jobs
  # Only load active organizations
  config.job_scope = ->{ where(status: :active) }
end

# Enable Sidekiq integration for background jobs
require 'acts_as_tenant/sidekiq'
```

#### 5.4.3 Update Application Controller
```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Set up acts_as_tenant
  set_current_tenant_through_filter
  before_action :authenticate_user!
  before_action :set_current_tenant

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActsAsTenant::Errors::NoTenantSet, with: :no_tenant_set

  private

  def set_current_tenant
    return unless user_signed_in?

    # Find organization from params or user's default
    organization = if params[:organization_id]
      current_user.organizations.find(params[:organization_id])
    elsif params[:org_slug]
      current_user.organizations.find_by!(slug: params[:org_slug])
    else
      current_user.organizations.first
    end

    ActsAsTenant.current_tenant = organization
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def no_tenant_set
    flash[:alert] = "Please select an organization."
    redirect_to organizations_path
  end

  helper_method :current_organization

  def current_organization
    ActsAsTenant.current_tenant
  end
end
```

#### 5.4.4 Testing Configuration
```ruby
# spec/rails_helper.rb (add to existing configuration)

RSpec.configure do |config|
  # ... existing configuration ...

  # Clear tenant after each test
  config.after(:each) do
    ActsAsTenant.current_tenant = nil
    ActsAsTenant.test_tenant = nil
  end

  # For request specs, use test_tenant
  config.before(:each, type: :request) do
    ActsAsTenant.test_tenant = FactoryBot.create(:organization)
  end

  # For other specs, use current_tenant
  config.before(:each, type: :model) do
    ActsAsTenant.current_tenant = FactoryBot.create(:organization)
  end
end
```

```ruby
# config/environments/test.rb (add middleware for integration tests)
require_dependency 'acts_as_tenant/test_tenant_middleware'

Rails.application.configure do
  # ... existing configuration ...

  config.middleware.use ActsAsTenant::TestTenantMiddleware
end
```

---

### 6. Organization Models

#### 6.1 Generate Organization Model
```bash
rails generate model Organization name:string slug:string plan:string status:string owner_id:integer
```

```ruby
# db/migrate/XXXXXX_create_organizations.rb
class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :plan, default: "free", null: false
      t.string :status, default: "active", null: false
      t.references :owner, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :organizations, :slug, unique: true
  end
end
```

```ruby
# app/models/organization.rb
class Organization < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: "User"
  has_many :organization_memberships, dependent: :destroy
  has_many :members, through: :organization_memberships, source: :user
  has_many :api_configurations, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

  # Enums
  enum :plan, { free: "free", starter: "starter", professional: "professional", enterprise: "enterprise" }
  enum :status, { active: "active", suspended: "suspended", cancelled: "cancelled" }

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? }

  # Scopes
  scope :active, -> { where(status: :active) }

  private

  def generate_slug
    self.slug = name.parameterize if name.present?
  end
end
```

#### 6.2 Generate OrganizationMembership Model
```bash
rails generate model OrganizationMembership organization:references user:references role:string
```

```ruby
# db/migrate/XXXXXX_create_organization_memberships.rb
class CreateOrganizationMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, default: "member", null: false

      t.timestamps
    end

    add_index :organization_memberships, [:organization_id, :user_id], unique: true
  end
end
```

```ruby
# app/models/organization_membership.rb
class OrganizationMembership < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :organization

  # Note: acts_as_tenant automatically adds:
  # - belongs_to :organization
  # - default_scope to filter by current tenant
  # - validation to prevent cross-tenant associations

  # Associations
  belongs_to :user

  # Validations
  validates :user_id, uniqueness: { scope: :organization_id }
  validates :role, presence: true

  # Enums
  enum :role, { viewer: "viewer", member: "member", admin: "admin", owner: "owner" }

  # Scopes
  scope :active, -> { joins(:organization).where(organizations: { status: :active }) }
end
```

#### 6.3 Generate ApiConfiguration Model
```bash
rails generate model ApiConfiguration organization:references provider:string key_name:string encrypted_api_key:text is_active:boolean last_validated_at:datetime
```

```ruby
# db/migrate/XXXXXX_create_api_configurations.rb
class CreateApiConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :api_configurations do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :key_name, null: false
      t.text :encrypted_api_key
      t.boolean :is_active, default: true
      t.datetime :last_validated_at

      t.timestamps
    end

    add_index :api_configurations, [:organization_id, :provider, :key_name],
              unique: true, name: 'index_api_configs_on_org_provider_name'
  end
end
```

```ruby
# app/models/api_configuration.rb
class ApiConfiguration < ApplicationRecord
  # Multi-tenancy
  acts_as_tenant :organization

  # Note: acts_as_tenant automatically adds:
  # - belongs_to :organization
  # - default_scope to filter by current tenant
  # - validation to prevent cross-tenant associations

  # Encryption
  encrypts :encrypted_api_key

  # Validations
  validates :provider, presence: true
  validates :key_name, presence: true
  validates :encrypted_api_key, presence: true
  # Use validates_uniqueness_to_tenant for tenant-scoped uniqueness
  validates_uniqueness_to_tenant :key_name, scope: :provider

  # Enums
  enum :provider, {
    openai: "openai",
    anthropic: "anthropic",
    google: "google",
    azure_openai: "azure_openai"
  }

  # Scopes
  scope :active, -> { where(is_active: true) }

  # Methods
  def masked_key
    return nil unless encrypted_api_key
    "****#{encrypted_api_key.last(4)}"
  end

  def validate_key!
    # TODO: Implement provider-specific validation
    update(last_validated_at: Time.current)
  end
end
```

---

### 7. Update CI/CD Pipeline

#### 7.1 Update GitHub Actions
```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
  push:
    branches: [ master ]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: make_ai_great_again_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    env:
      RAILS_ENV: test
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/make_ai_great_again_test

    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Setup database
        run: |
          bin/rails db:create
          bin/rails db:migrate

      - name: Run tests
        run: bundle exec rspec

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        if: always()

  scan_ruby:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Scan for security vulnerabilities
        run: bin/brakeman --no-pager

      - name: Scan for known security vulnerabilities in gems
        run: bin/bundler-audit

  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Lint code
        run: bin/rubocop -f github
```

---

### 8. Environment Configuration

#### 8.1 Create .env.example
```bash
# .env.example
DATABASE_URL=postgres://localhost/make_ai_great_again_development
REDIS_URL=redis://localhost:6379/0

# Email (for Devise)
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_sendgrid_api_key
SMTP_DOMAIN=makeaigreatagain.com

# Application
APP_HOST=localhost:3000
APP_PROTOCOL=http

# Optional: Error tracking
SENTRY_DSN=
```

#### 8.2 Update .gitignore
```
# .gitignore
/.env
/.env.local
/.env.*.local
```

---

## Testing Strategy

### Unit Tests
- Model validations
- Model associations
- Model methods
- Policy authorization rules

### Integration Tests
- User registration flow
- User login/logout
- Organization creation
- Member invitation
- API key management

### System Tests
- End-to-end user journeys
- Multi-browser testing
- Responsive design testing

---

## Next Steps

After completing Phase 1, proceed to:
1. **Phase 2**: PromptTracker Integration
2. **Phase 3**: Team Collaboration Features
3. **Phase 4**: Landing Page & Onboarding
4. **Phase 5**: Polish & Launch Prep

---

## Checklist

### Database
- [ ] PostgreSQL installed and running
- [ ] Database created
- [ ] Migrations run successfully

### Testing
- [ ] RSpec installed and configured
- [ ] FactoryBot configured
- [ ] SimpleCov configured
- [ ] All tests passing

### Authentication
- [ ] Devise installed
- [ ] User model created
- [ ] Authentication flows working
- [ ] Email confirmation working

### Authorization
- [ ] Pundit installed
- [ ] Base policies created
- [ ] Authorization working

### Multi-Tenancy
- [ ] acts_as_tenant gem installed
- [ ] acts_as_tenant configured
- [ ] ApplicationController updated with tenant management
- [ ] Sidekiq integration enabled
- [ ] Test configuration updated

### Models
- [ ] Organization model created
- [ ] OrganizationMembership model created
- [ ] ApiConfiguration model created
- [ ] All associations working

### Frontend
- [ ] Bootstrap 5 installed
- [ ] Responsive layout created
- [ ] Navigation working
- [ ] Flash messages styled

### CI/CD
- [ ] GitHub Actions updated
- [ ] Tests running in CI
- [ ] Security scans passing
- [ ] Linting passing

---

**Last Updated**: 2026-02-24
