# MakeAiGreatAgain - PromptTracker Platform

A multi-tenant SaaS platform providing enterprise-grade prompt management and LLM tracking capabilities through the [PromptTracker](https://github.com/DavidGeismarLtd/PromptTracker) engine.

## 🎯 What is This?

MakeAiGreatAgain is the **host application** that wraps the PromptTracker engine, providing:

- 🔐 **Authentication & User Management** - Secure user accounts with Devise
- 👥 **Multi-Tenancy** - Organizations/teams with role-based access control
- 🔑 **API Key Management** - Encrypted storage of LLM provider API keys
- 🎨 **Landing Page** - Marketing and onboarding experience
- 📊 **Configuration** - Organization-level settings and preferences

The **PromptTracker engine** provides the core features:
- ✨ Prompt versioning and management
- 📈 LLM call tracking and analytics
- 🧪 Automated evaluation and testing
- 🔬 A/B testing and experiments
- 🤖 Multi-provider support (OpenAI, Anthropic, Google)

---

## 📚 Documentation

- **[Product Requirements Document (PRD)](docs/PRD.md)** - Complete product vision, features, and requirements
- **[Technical Implementation Plan](docs/TECHNICAL_IMPLEMENTATION_PLAN.md)** - Step-by-step development guide
- **[Database Schema](docs/DATABASE_SCHEMA.md)** - Database structure and relationships
- **[Quick Start Guide](docs/QUICK_START.md)** - Get up and running in 5 minutes

---

## 🚀 Quick Start

### Prerequisites

- Ruby 3.3.5
- Rails 8.1.2
- PostgreSQL 16+
- Redis 7+

### Setup

```bash
# Clone the repository
git clone https://github.com/DavidGeismarLtd/make_ai_great_again.git
cd make_ai_great_again

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed

# Start the application
bin/dev
```

Visit http://localhost:3000

For detailed setup instructions, see the [Quick Start Guide](docs/QUICK_START.md).

---

## 🧪 Testing

```bash
# Run all tests
bundle exec rspec

# Run with coverage
COVERAGE=true bundle exec rspec

# Run security scans
bin/brakeman
bin/bundler-audit

# Run linter
bin/rubocop
```

---

## 🏗️ Tech Stack

- **Backend**: Ruby on Rails 8.1.2
- **Database**: PostgreSQL
- **Background Jobs**: Sidekiq + Redis
- **Authentication**: Devise
- **Authorization**: Pundit
- **Frontend**: Bootstrap 5 + Hotwire (Turbo + Stimulus)
- **Testing**: RSpec + FactoryBot + Capybara
- **Deployment**: Kamal (Docker)

---

## 📋 Current Status

**Phase**: Foundation Setup (Phase 1 of 5)

### Completed
- ✅ Initial Rails 8 application setup
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Documentation structure

### In Progress
- 🔄 PostgreSQL migration
- 🔄 RSpec setup
- 🔄 Bootstrap 5 integration
- 🔄 Devise authentication
- 🔄 Pundit authorization
- 🔄 Organization models

### Upcoming
- ⏳ PromptTracker engine integration
- ⏳ API key management
- ⏳ Team collaboration features
- ⏳ Landing page
- ⏳ Onboarding flow

See [PRD.md](docs/PRD.md) for complete roadmap.

---

## 🤝 Contributing

1. Read the [PRD](docs/PRD.md) to understand the product vision
2. Check the [Technical Implementation Plan](docs/TECHNICAL_IMPLEMENTATION_PLAN.md)
3. Create a feature branch
4. Write tests for your changes
5. Ensure all tests and linters pass
6. Submit a pull request

---

## 📄 License

This project is proprietary software. All rights reserved.

---

## 🔗 Related Projects

- [PromptTracker Engine](https://github.com/DavidGeismarLtd/PromptTracker) - Core prompt management engine

---

## 📞 Contact

For questions or support, please create an issue on GitHub.

---

**Built with ❤️ by David Geismar**
