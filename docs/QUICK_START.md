# Quick Start Guide
## MakeAiGreatAgain - PromptTracker Platform

**For Developers** | **Last Updated**: 2026-02-24

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **Ruby**: 3.3.5 (use rbenv or rvm)
- **Rails**: 8.1.2
- **PostgreSQL**: 16+ (running locally or via Docker)
- **Redis**: 7+ (for Sidekiq background jobs)
- **Node.js**: 20+ (for JavaScript dependencies)
- **Git**: Latest version

---

## Initial Setup (5 minutes)

### 1. Clone the Repository

```bash
git clone https://github.com/DavidGeismarLtd/make_ai_great_again.git
cd make_ai_great_again
```

### 2. Install Dependencies

```bash
# Install Ruby gems
bundle install

# Install JavaScript dependencies (if any)
# npm install  # Not needed for importmap setup
```

### 3. Setup Database

```bash
# Create databases
rails db:create

# Run migrations
rails db:migrate

# Seed sample data (optional)
rails db:seed
```

### 4. Configure Environment Variables

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your settings
# At minimum, configure:
# - DATABASE_URL (if not using default)
# - REDIS_URL (if not using default)
```

### 5. Start the Application

```bash
# Start Rails server
bin/dev

# Or manually start services:
# Terminal 1: Rails server
rails server

# Terminal 2: Sidekiq (background jobs)
bundle exec sidekiq
```

### 6. Visit the Application

Open your browser and navigate to:
- **Application**: http://localhost:3000
- **PromptTracker** (after Phase 2): http://localhost:3000/orgs/your-org/app

---

## Running Tests

### Run All Tests

```bash
# Run entire test suite
bundle exec rspec

# Run with coverage report
COVERAGE=true bundle exec rspec
```

### Run Specific Tests

```bash
# Run specific file
bundle exec rspec spec/models/user_spec.rb

# Run specific test
bundle exec rspec spec/models/user_spec.rb:10

# Run tests matching pattern
bundle exec rspec spec/models/
```

### Check Test Coverage

```bash
# Generate coverage report
COVERAGE=true bundle exec rspec

# Open coverage report
open coverage/index.html
```

---

## Common Development Tasks

### Database Operations

```bash
# Reset database (drop, create, migrate, seed)
rails db:reset

# Rollback last migration
rails db:rollback

# Check migration status
rails db:migrate:status

# Open database console
rails dbconsole
```

### Code Quality

```bash
# Run RuboCop linter
bin/rubocop

# Auto-fix RuboCop issues
bin/rubocop -a

# Run security scan
bin/brakeman

# Audit gems for vulnerabilities
bin/bundler-audit
```

### Rails Console

```bash
# Open Rails console
rails console

# Common console commands:
# User.count
# Organization.first
# User.find_by(email: 'user@example.com')
```

### Generate Code

```bash
# Generate model
rails generate model ModelName field:type

# Generate controller
rails generate controller ControllerName action1 action2

# Generate migration
rails generate migration AddFieldToTable field:type

# Generate RSpec tests
rails generate rspec:model ModelName
rails generate rspec:controller ControllerName
```

---

## Project Structure

```
make_ai_great_again/
├── app/
│   ├── controllers/      # Request handlers
│   ├── models/           # Data models
│   ├── views/            # HTML templates
│   ├── policies/         # Authorization policies (Pundit)
│   ├── javascript/       # Stimulus controllers
│   └── assets/           # CSS, images
├── config/
│   ├── routes.rb         # URL routing
│   ├── database.yml      # Database configuration
│   └── initializers/     # App initialization
├── db/
│   ├── migrate/          # Database migrations
│   └── seeds.rb          # Sample data
├── spec/                 # RSpec tests
│   ├── models/
│   ├── controllers/
│   ├── requests/
│   └── system/
├── docs/                 # Documentation
│   ├── PRD.md
│   ├── TECHNICAL_IMPLEMENTATION_PLAN.md
│   └── DATABASE_SCHEMA.md
└── Gemfile              # Ruby dependencies
```

---

## Key Concepts

### Authentication (Devise)

```ruby
# In controllers
before_action :authenticate_user!

# In views
<% if user_signed_in? %>
  <%= current_user.email %>
<% end %>

# Sign out
<%= button_to "Sign Out", destroy_user_session_path, method: :delete %>
```

### Authorization (Pundit)

```ruby
# In controllers
authorize @organization

# In policies
class OrganizationPolicy < ApplicationPolicy
  def update?
    user.admin_of?(record)
  end
end

# In views
<% if policy(@organization).update? %>
  <%= link_to "Edit", edit_organization_path(@organization) %>
<% end %>
```

### Multi-Tenancy

```ruby
# Scope resources by organization
@prompts = current_organization.prompts

# Check organization membership
current_user.organizations.include?(@organization)

# Get user's role in organization
current_user.organization_memberships
  .find_by(organization: @organization)
  &.role
```

---

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
pg_isready

# Restart PostgreSQL (macOS with Homebrew)
brew services restart postgresql@16

# Check database exists
rails db:migrate:status
```

### Redis Connection Issues

```bash
# Check Redis is running
redis-cli ping
# Should return: PONG

# Restart Redis (macOS with Homebrew)
brew services restart redis
```

### Asset Issues

```bash
# Clear asset cache
rails assets:clobber

# Precompile assets
rails assets:precompile
```

### Test Failures

```bash
# Reset test database
RAILS_ENV=test rails db:reset

# Clear test cache
rails tmp:clear
```

---

## Next Steps

1. **Read the PRD**: Understand the product vision and requirements
2. **Review Technical Plan**: Follow Phase 1 implementation steps
3. **Set up your IDE**: Configure RuboCop, Solargraph, etc.
4. **Join the team**: Ask questions, contribute code!

---

## Useful Resources

- **Rails Guides**: https://guides.rubyonrails.org/
- **RSpec Documentation**: https://rspec.info/
- **Devise Wiki**: https://github.com/heartcombo/devise/wiki
- **Pundit README**: https://github.com/varvet/pundit
- **Bootstrap Docs**: https://getbootstrap.com/docs/5.3/
- **PromptTracker Repo**: https://github.com/DavidGeismarLtd/PromptTracker

---

## Getting Help

- **Documentation**: Check `/docs` folder
- **Issues**: Create GitHub issue
- **Questions**: Ask in team chat

---

**Happy Coding! 🚀**

