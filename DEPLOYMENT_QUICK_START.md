# Deployment Quick Start Guide

## Prerequisites

1. **Redis** - Required for Sidekiq background jobs
2. **PostgreSQL** - Required for the application database
3. **Docker** - For containerized deployment (if using Kamal)

---

## Option 1: Deploy to Render.com (Easiest)

### Step 1: Create Render Account
Sign up at https://render.com

### Step 2: Create Services

#### A. PostgreSQL Database
1. Click "New +" → "PostgreSQL"
2. Name: `make-ai-great-again-db`
3. Plan: Starter ($7/month)
4. Click "Create Database"
5. **Save the Internal Database URL** (starts with `postgres://`)

#### B. Redis Instance
1. Click "New +" → "Redis"
2. Name: `make-ai-great-again-redis`
3. Plan: Starter ($10/month)
4. Click "Create Redis"
5. **Save the Internal Redis URL** (starts with `redis://`)

#### C. Web Service (Rails App)
1. Click "New +" → "Web Service"
2. Connect your GitHub repository
3. Configure:
   - **Name**: `make-ai-great-again-web`
   - **Environment**: Ruby
   - **Build Command**: `bundle install && bundle exec rake assets:precompile`
   - **Start Command**: `bundle exec puma -C config/puma.rb`
   - **Plan**: Starter ($25/month)

4. Add Environment Variables:
   ```
   RAILS_ENV=production
   RAILS_MASTER_KEY=<from config/master.key>
   DATABASE_URL=<PostgreSQL Internal URL from step A>
   REDIS_URL=<Redis Internal URL from step B>
   SECRET_KEY_BASE=<generate with: rails secret>
   ```

5. Click "Create Web Service"

#### D. Background Worker (Sidekiq)
1. Click "New +" → "Background Worker"
2. Connect same GitHub repository
3. Configure:
   - **Name**: `make-ai-great-again-worker`
   - **Environment**: Ruby
   - **Build Command**: `bundle install`
   - **Start Command**: `bundle exec sidekiq -C config/sidekiq.yml`
   - **Plan**: Starter ($25/month)

4. Add same Environment Variables as Web Service

5. Click "Create Background Worker"

### Step 3: Run Database Migrations
1. Go to Web Service → "Shell" tab
2. Run:
   ```bash
   bundle exec rails db:migrate
   bundle exec rails db:seed  # Optional: seed sample data
   ```

### Step 4: Access Your App
- Your app will be available at: `https://make-ai-great-again-web.onrender.com`
- You can add a custom domain in Render settings

**Total Monthly Cost**: ~$67/month

---

## Option 2: Deploy with Kamal (Self-Hosted)

### Prerequisites
- A VPS server (Hetzner, DigitalOcean, AWS, etc.)
- Docker installed on the server
- SSH access to the server

### Step 1: Setup Server
```bash
# SSH into your server
ssh root@your-server-ip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
```

### Step 2: Setup Redis
```bash
# Option A: Docker Redis
docker run -d --name redis \
  --restart unless-stopped \
  -p 6379:6379 \
  redis:7-alpine

# Option B: Use managed Redis (recommended for production)
# - Upstash: https://upstash.com (free tier available)
# - Redis Cloud: https://redis.com/try-free
```

### Step 3: Setup PostgreSQL
```bash
# Option A: Docker PostgreSQL
docker run -d --name postgres \
  --restart unless-stopped \
  -e POSTGRES_PASSWORD=your_password \
  -e POSTGRES_DB=make_ai_great_again_production \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:16-alpine

# Option B: Use managed PostgreSQL (recommended for production)
# - Hetzner Cloud: https://www.hetzner.com/cloud/managed-database
# - DigitalOcean: https://www.digitalocean.com/products/managed-databases
```

### Step 4: Configure Kamal

1. **Update `config/deploy.yml`**:
   ```yaml
   servers:
     web:
       - YOUR_SERVER_IP
     job:
       hosts:
         - YOUR_SERVER_IP
       cmd: bin/jobs
   
   registry:
     server: ghcr.io
     username: DavidGeismarLtd
     password:
       - KAMAL_REGISTRY_PASSWORD
   ```

2. **Create `.kamal/secrets`**:
   ```bash
   mkdir -p .kamal
   cat > .kamal/secrets << EOF
   KAMAL_REGISTRY_PASSWORD=<your-github-token>
   RAILS_MASTER_KEY=$(cat config/master.key)
   REDIS_URL=redis://your-server-ip:6379/0
   DATABASE_PASSWORD=your_db_password
   DATABASE_USERNAME=postgres
   DATABASE_HOST=your-server-ip
   EOF
   ```

3. **Generate GitHub Token** (for container registry):
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scopes: `write:packages`, `read:packages`
   - Copy the token and use it as `KAMAL_REGISTRY_PASSWORD`

### Step 5: Deploy
```bash
# First deployment (sets up everything)
bin/kamal setup

# Run migrations
bin/kamal app exec 'bin/rails db:migrate'
bin/kamal app exec 'bin/rails db:seed'  # Optional

# Future deployments
bin/kamal deploy
```

### Step 6: Useful Kamal Commands
```bash
# View logs
bin/kamal app logs -f          # Web server logs
bin/kamal app logs -f -r job   # Sidekiq worker logs

# SSH into container
bin/kamal app exec --interactive bash

# Rails console
bin/kamal console

# Restart services
bin/kamal app restart          # Restart web
bin/kamal app restart -r job   # Restart workers

# Check status
bin/kamal app details
```

**Estimated Monthly Cost**: €20-40 (Hetzner VPS + managed DB)

---

## Post-Deployment Checklist

- [ ] Verify web app is accessible
- [ ] Check Sidekiq workers are running
- [ ] Test user registration/login
- [ ] Test background jobs (check Sidekiq logs)
- [ ] Setup SSL certificate (automatic with Kamal + Thruster)
- [ ] Configure custom domain (optional)
- [ ] Setup monitoring (optional: Sentry, New Relic, etc.)
- [ ] Setup backups for database
- [ ] Test API key encryption/decryption

---

## Troubleshooting

### Web app not starting
```bash
# Check logs
bin/kamal app logs

# Common issues:
# - Missing RAILS_MASTER_KEY
# - Database connection failed
# - Redis connection failed
```

### Sidekiq not processing jobs
```bash
# Check worker logs
bin/kamal app logs -r job

# Verify Redis connection
bin/kamal app exec 'rails runner "puts Redis.new(url: ENV[\"REDIS_URL\"]).ping"'
```

### Database connection errors
```bash
# Test database connection
bin/kamal app exec 'rails runner "puts ActiveRecord::Base.connection.execute(\"SELECT 1\").to_a"'
```

---

## Support

For issues or questions:
1. Check logs: `bin/kamal app logs`
2. Review configuration files
3. Verify environment variables are set correctly
4. Check server resources (CPU, memory, disk)

---

**Last Updated**: 2026-03-02

