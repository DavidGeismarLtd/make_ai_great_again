# Render.com Deployment Guide

Complete guide for deploying Make AI Great Again to Render.com with all required services.

## Prerequisites

- GitHub/GitLab/Bitbucket repository with your code
- Render.com account (free tier available)

## Deployment Options

### Option 1: Using Blueprint (Recommended - Infrastructure as Code)

This method uses the `render.yaml` file to automatically create all services.

1. **Push your code to GitHub**
   ```bash
   git add .
   git commit -m "Add Render deployment configuration"
   git push
   ```

2. **Create Blueprint in Render**
   - Go to https://dashboard.render.com/blueprints
   - Click "New Blueprint Instance"
   - Connect your repository
   - Render will detect `render.yaml` automatically
   - You'll be prompted to provide:
     - `RAILS_MASTER_KEY`: Get from `config/master.key` (value: `95bee6f64bd642330ac0ec6bb7607c0e`)

3. **Set up Redis (Choose one)**

   **Option A: Use Render Redis (Limited Free Tier)**
   - Uncomment the Redis section in `render.yaml`
   - Redeploy the blueprint
   - Note: Free tier is limited to 25MB

   **Option B: Use Upstash Redis (Recommended for Free Tier)**
   - Go to https://upstash.com (free tier: 10,000 commands/day)
   - Create a new Redis database
   - Copy the Redis URL
   - Add `REDIS_URL` environment variable to both web and worker services in Render dashboard

   **Option C: Use Redis Cloud**
   - Go to https://redis.com/try-free/
   - Create a free database (30MB free)
   - Copy the Redis URL
   - Add `REDIS_URL` environment variable to both web and worker services

4. **Deploy**
   - Render will automatically deploy all services
   - Monitor the build logs

### Option 2: Manual Setup (Step by Step)

If you prefer to set up services manually:

#### Step 1: Create PostgreSQL Database

1. Go to Render Dashboard → "New +" → "PostgreSQL"
2. Configure:
   - Name: `make-ai-great-again-db`
   - Database: `make_ai_great_again_db`
   - User: `make_ai_great_again_user`
   - Region: Choose closest to your users
   - Plan: Free (or Starter for production)
3. Click "Create Database"
4. Wait for database to be created (~2 minutes)

#### Step 2: Create Redis Instance

Choose one of the options from above (Upstash recommended for free tier).

#### Step 3: Create Web Service

1. Go to Render Dashboard → "New +" → "Web Service"
2. Connect your repository
3. Configure:
   - Name: `make-ai-great-again`
   - Runtime: Ruby
   - Build Command: `./bin/render-build.sh`
   - Start Command: `bundle exec puma -C config/puma.rb`
   - Plan: Free (or Starter for production)
4. Add Environment Variables:
   - `RAILS_MASTER_KEY`: `95bee6f64bd642330ac0ec6bb7607c0e`
   - `WEB_CONCURRENCY`: `2`
   - `RAILS_MAX_THREADS`: `5`
   - `RAILS_ENV`: `production`
5. Connect Database:
   - Scroll to "Environment" section
   - Click "Add from Database"
   - Select your PostgreSQL database
   - This automatically adds `DATABASE_URL`
6. Add Redis URL:
   - Add environment variable `REDIS_URL` with your Redis connection string
7. Click "Create Web Service"

#### Step 4: Create Background Worker (Sidekiq)

1. Go to Render Dashboard → "New +" → "Background Worker"
2. Connect your repository
3. Configure:
   - Name: `make-ai-great-again-sidekiq`
   - Runtime: Ruby
   - Build Command: `bundle install`
   - Start Command: `bundle exec sidekiq -C config/sidekiq.yml`
   - Plan: Free (or Starter for production)
4. Add Environment Variables (same as web service):
   - `RAILS_MASTER_KEY`: `95bee6f64bd642330ac0ec6bb7607c0e`
   - `RAILS_ENV`: `production`
   - `DATABASE_URL`: (connect from database)
   - `REDIS_URL`: (your Redis connection string)
5. Click "Create Background Worker"

## Post-Deployment

### Verify Deployment

1. **Check Web Service**
   - Visit your Render URL (e.g., `https://make-ai-great-again.onrender.com`)
   - Should see the homepage

2. **Check Health Endpoint**
   - Visit `https://make-ai-great-again.onrender.com/up`
   - Should return "OK" with 200 status

3. **Check Logs**
   - Web Service logs: Should show Puma starting with 2 workers
   - Sidekiq logs: Should show Sidekiq starting and connecting to Redis

4. **Test Database**
   - Try signing up for an account
   - Should create user successfully

5. **Test Background Jobs**
   - Trigger a background job (if you have any)
   - Check Sidekiq logs to verify it processes

### Monitoring

- **Logs**: Available in Render dashboard for each service
- **Metrics**: CPU, Memory, Request count available in dashboard
- **Health Checks**: Render automatically monitors `/up` endpoint

## Troubleshooting

### Database Connection Issues
- Verify `DATABASE_URL` is set correctly
- Check database is running and accessible
- Review `config/database.yml` configuration

### Redis Connection Issues
- Verify `REDIS_URL` is set in both web and worker services
- Test Redis connection: `redis-cli -u $REDIS_URL ping`
- Check Redis service is running

### Build Failures
- Check build logs for specific errors
- Verify `bin/render-build.sh` is executable
- Ensure all dependencies are in Gemfile

### Sidekiq Not Processing Jobs
- Verify worker service is running
- Check `REDIS_URL` is set correctly
- Review Sidekiq logs for errors
- Ensure jobs are being enqueued

## Scaling

### Free Tier Limitations
- Web service: Spins down after 15 minutes of inactivity
- Database: 1GB storage, 97 hours/month
- Redis (if using Render): 25MB storage

### Upgrading for Production
1. Upgrade database to Starter plan ($7/month)
2. Upgrade web service to Starter plan ($7/month)
3. Upgrade worker to Starter plan ($7/month)
4. Consider paid Redis provider for better performance

## Cost Estimate

### Free Tier (Development)
- Web Service: Free
- Worker: Free
- PostgreSQL: Free
- Redis (Upstash): Free
- **Total: $0/month**

### Starter Tier (Production)
- Web Service: $7/month
- Worker: $7/month
- PostgreSQL: $7/month
- Redis (Upstash Pro or Redis Cloud): $5-10/month
- **Total: ~$26-31/month**

## Additional Resources

- [Render Rails 8 Guide](https://render.com/docs/deploy-rails-8)
- [Render Blueprint Spec](https://render.com/docs/blueprint-spec)
- [Render Environment Variables](https://render.com/docs/environment-variables)
- [Sidekiq on Render](https://render.com/docs/deploy-sidekiq)

