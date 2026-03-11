# Testing the Invitation System

This guide will help you test the organization invitation system with email previews.

## Setup

The `letter_opener` gem is already configured in development. When you send an email in development, it will automatically open in your browser instead of being sent.

**Important**: The controllers are configured to use `deliver_now` in development (so emails open immediately) and `deliver_later` in production (for background processing with Sidekiq).

## Quick Test via Rails Console

1. Start the Rails console:
   ```bash
   rails console
   ```

2. Create and send a test invitation:
   ```ruby
   # Set the current tenant
   org = Organization.first
   ActsAsTenant.current_tenant = org

   # Create a test invitation
   user = User.first
   invitation = org.organization_invitations.create!(
     email: "test@example.com",
     role: "member",
     invited_by: user
   )

   # Send the invitation email (will open in browser)
   OrganizationInvitationMailer.invite(invitation).deliver_now
   ```

3. The email will automatically open in your default browser!

## Testing via Web Interface

1. **Start the Rails server**:
   ```bash
   rails server
   ```

2. **Sign in as admin**:
   - Go to `http://localhost:3000`
   - Sign in with `admin@example.com` / `password123`

3. **Navigate to Invitations**:
   - Go to Organization Settings: `http://localhost:3000/orgs/acme-corp/settings`
   - Click "Manage Invitations" button
   - Or go directly to: `http://localhost:3000/orgs/acme-corp/invitations`

4. **Send an Invitation**:
   - Click "Send Invitation"
   - Enter an email address (e.g., `newuser@example.com`)
   - Select a role (Viewer, Member, or Admin)
   - Click "Send Invitation"
   - **The email will automatically open in your browser!**

5. **Test the Invitation Flow - New User**:
   - Copy the invitation URL from the email (e.g., `http://localhost:3000/invitations/TOKEN`)
   - Open it in an incognito/private window
   - You'll see a registration form with:
     - Email (pre-filled and disabled)
     - First Name
     - Last Name
     - Password
     - Password Confirmation
   - Fill in the form and click \"Create Account & Join Organization\"
   - You'll be automatically signed in and added to the organization!

6. **Test the Invitation Flow - Existing User**:
   - Send an invitation to an existing user's email
   - Click the invitation link
   - You'll be redirected to sign in
   - After signing in, you'll see a confirmation page
   - Click \"Accept Invitation\" to join the organization

## Testing Email Confirmation

1. **Sign up a new user**:
   - Go to `http://localhost:3000/users/sign_up`
   - Fill in the form
   - Click "Sign up"
   - **The confirmation email will automatically open in your browser!**

2. **Click the confirmation link** in the email to confirm your account

## Viewing Sent Emails

All emails sent in development are saved to `tmp/letter_opener/` and will automatically open in your browser when sent.

## Testing Different Scenarios

### Expired Invitation
```ruby
# In Rails console
invitation = OrganizationInvitation.last
invitation.update(expires_at: 1.day.ago)
# Now visit the invitation URL - you'll see the "expired" page
```

### Already Accepted Invitation
```ruby
# In Rails console
invitation = OrganizationInvitation.last
invitation.update(accepted_at: Time.current)
# Now visit the invitation URL - you'll see the "already accepted" page
```

### Resend Invitation
- Go to the invitations page
- Click the "Resend" button (arrow icon) next to a pending invitation
- The email will open in your browser again

### Cancel Invitation
- Go to the invitations page
- Click the "Cancel" button (trash icon) next to a pending invitation
- Confirm the deletion

## Troubleshooting

If emails don't open automatically:
1. Check `tmp/letter_opener/` directory for saved emails
2. Make sure `config/environments/development.rb` has:
   ```ruby
   config.action_mailer.delivery_method = :letter_opener
   ```
3. Restart the Rails server after making configuration changes

## Email Preview URLs

You can also preview emails without sending them using Rails' email previews:
- Visit `http://localhost:3000/rails/mailers`
- Click on "OrganizationInvitationMailer"
- Click on "invite" to see the email preview
