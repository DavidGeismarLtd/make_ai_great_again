# Resend Email Configuration

This application uses [Resend](https://resend.com) as the email delivery service **for production only**.

## Setup Instructions

### 1. Get Your Resend API Key (Production Only)

1. Sign up for a Resend account at [https://resend.com](https://resend.com)
2. Verify your domain at [https://resend.com/domains](https://resend.com/domains)
3. Create an API key at [https://resend.com/api-keys](https://resend.com/api-keys)

### 2. Configure Production Environment Variables

Add the following to your **production environment** (e.g., Heroku, Kamal, etc.):

```bash
RESEND_API_KEY=re_xxxxxxxxx
MAILER_FROM_ADDRESS=noreply@yourdomain.com
APP_HOST=yourdomain.com
```

**Important:**
- The `MAILER_FROM_ADDRESS` must use a domain that you've verified with Resend
- These variables are **NOT needed in development** - development uses `letter_opener`

### 3. Environment-Specific Behavior

- **Development**: Uses `letter_opener` gem to preview emails in your browser (no actual emails sent, no Resend needed)
- **Test**: Uses `:test` delivery method (emails stored in `ActionMailer::Base.deliveries`, no Resend needed)
- **Production**: Uses Resend to send actual emails (requires Resend API key)

## Usage

### Sending Emails

Emails are sent using standard Rails Action Mailer:

```ruby
# Example: Send organization invitation
OrganizationInvitationMailer.invite(invitation).deliver_now

# Or deliver later (using Sidekiq)
OrganizationInvitationMailer.invite(invitation).deliver_later
```

### Testing Emails in Development

When you send an email in development, it will automatically open in your browser thanks to the `letter_opener` gem.

### Verifying Your Domain

Before you can send emails in production, you must verify your domain with Resend:

1. Go to [https://resend.com/domains](https://resend.com/domains)
2. Add your domain
3. Add the DNS records provided by Resend to your domain's DNS settings
4. Wait for verification (usually takes a few minutes)

## Configuration Files

- `config/initializers/resend.rb` - Sets the Resend API key
- `config/environments/production.rb` - Configures Action Mailer to use Resend
- `config/environments/development.rb` - Configures Action Mailer to use letter_opener
- `app/mailers/application_mailer.rb` - Base mailer with default from address

## Troubleshooting

### Emails not sending in production

1. Verify your `RESEND_API_KEY` is set correctly
2. Ensure your domain is verified in Resend
3. Check that `MAILER_FROM_ADDRESS` uses your verified domain
4. Check Rails logs for error messages

### Testing in development

If emails aren't opening in your browser:
1. Make sure the `letter_opener` gem is installed
2. Restart your Rails server
3. Check the Rails logs for the email preview URL

## Resources

- [Resend Documentation](https://resend.com/docs)
- [Resend Rails Guide](https://resend.com/docs/send-with-rails)
- [Resend Ruby SDK](https://github.com/resend/resend-ruby)
