# Shared Layout & Navigation - Product Requirements Document

**Version**: 1.0
**Date**: 2026-02-26
**Status**: Draft
**Priority**: P0 (Must Have)

---

## 1. Executive Summary

This PRD defines the implementation of a unified navigation and layout system that seamlessly integrates the host application (MakeAiGreatAgain) with the PromptTracker engine. The goal is to create a single, cohesive user experience where users don't feel like they're navigating between two different applications.

### Key Objectives
1. **Unified Navigation** - Single navbar that works across host app and engine
2. **Seamless Integration** - Override PromptTracker's layout to use host app navigation
3. **Organization Context** - Always show current organization and allow easy switching
4. **User Context** - Persistent user menu across all pages
5. **Professional Landing Page** - Marketing page for unauthenticated visitors
6. **Customized Auth Flows** - Branded Devise views matching overall design

---

## 2. Current State Analysis

### 2.1 PromptTracker Engine Navigation (Existing)

The PromptTracker engine currently has:
- **Logo**: Text-based logo with `>PromptTracker` branding
- **Main Navigation**:
  - Testing (blue) - `/testing`
  - Monitoring (green) - `/monitoring`
- **Search Bar** - Global prompt search
- **Theme Toggle** - Light/dark mode switcher
- **Breadcrumbs** - Contextual navigation
- **Footer** - Stats showing prompt/version/response counts

**What's Missing from PromptTracker**:
- ❌ Organization switcher
- ❌ User menu (profile, settings, sign out)
- ❌ Account management links
- ❌ Multi-tenancy awareness in navigation

### 2.2 Host App Current State

- ✅ Basic `application.html.erb` layout (no navigation)
- ✅ Placeholder landing page
- ❌ No navigation bar
- ❌ No Devise views customized
- ❌ No flash message styling
- ❌ No organization switcher

---

## 3. Design Philosophy

### 3.1 Core Principles

1. **Single Application Feel** - Users should never feel like they're switching between apps
2. **Context Preservation** - Organization and user context always visible
3. **Reuse PromptTracker Branding** - Keep the `>PromptTracker` logo and design system
4. **Extend, Don't Replace** - Add organization/user features to existing PromptTracker nav
5. **Responsive First** - Mobile, tablet, desktop support

### 3.2 Navigation Strategy

**Option A: Override PromptTracker Layout** ✅ **RECOMMENDED**
- Create `app/views/layouts/prompt_tracker/application.html.erb` in host app
- Render host app's unified navbar
- PromptTracker content renders within host app layout
- **Pros**: Single source of truth, easier maintenance, truly unified experience
- **Cons**: Need to recreate PromptTracker navbar elements

**Option B: Inject Elements into PromptTracker Layout** ❌ **NOT RECOMMENDED**
- Keep PromptTracker's layout
- Try to inject organization switcher and user menu
- **Pros**: Minimal changes to PromptTracker
- **Cons**: Fragile, hard to maintain, still feels like two apps

**Decision**: Go with **Option A** - Complete layout override for unified experience.

---

## 4. Detailed Requirements

### 4.1 Unified Navigation Bar

#### 4.1.1 Structure

```
┌─────────────────────────────────────────────────────────────────────────┐
│ >PromptTracker  │ Testing │ Monitoring │ [Search] │ [Org ▼] │ [User ▼] │
└─────────────────────────────────────────────────────────────────────────┘
```

**Left Side**:
- **Logo**: `>PromptTracker` (reuse PromptTracker branding)
  - Links to: Root path when not authenticated, current org dashboard when authenticated
  - Style: Same as PromptTracker engine (electric blue accent)

**Center/Left-Center**:
- **Testing** (when authenticated and in org context)
  - Icon: `<i class="bi bi-check2-square"></i>`
  - Links to: `/orgs/:org_slug/app/testing`
  - Active state: Blue highlight

- **Monitoring** (when authenticated and in org context)
  - Icon: `<i class="bi bi-activity"></i>`
  - Links to: `/orgs/:org_slug/app/monitoring`
  - Active state: Green highlight

- **Organizations** (NEW - when authenticated)
  - Icon: `<i class="bi bi-building"></i>`
  - Links to: `/organizations` (future - organization management page)
  - Shows: List of user's organizations, settings

- **API Keys** (NEW - when authenticated and in org context)
  - Icon: `<i class="bi bi-key"></i>`
  - Links to: `/orgs/:org_slug/api_keys`
  - Shows: Manage LLM provider API keys

**Right Side**:
- **Search Bar** (when authenticated and in org context)
  - Same as PromptTracker: Global prompt search
  - Placeholder: "Search prompts..."

- **Theme Toggle** (always visible)
  - Same as PromptTracker: Light/dark mode
  - Persists to localStorage

- **Organization Switcher** (NEW - when authenticated)
  - Shows: Current organization name
  - Dropdown: List of user's organizations
  - Action: Switch to different org (redirects to that org's dashboard)

- **User Menu** (NEW - when authenticated)
  - Shows: User's first name or email
  - Dropdown:
    - Profile
    - Account Settings
    - Sign Out

**Guest State** (when not authenticated):
- Logo only on left
- Right side: **Sign In** and **Sign Up** buttons

#### 4.1.2 Responsive Behavior

**Desktop (≥992px)**:
- Full navigation visible
- All items in single row

**Tablet (768px - 991px)**:
- Collapse to hamburger menu
- Organization switcher and user menu remain visible

**Mobile (<768px)**:
- Hamburger menu for all navigation
- Organization switcher in dropdown
- User menu in dropdown

#### 4.1.3 Active States

- **Current Section**: Highlight active nav item (Testing/Monitoring)
- **Current Organization**: Show in organization switcher
- **Breadcrumbs**: Show full path below navbar

---

### 4.2 Organization Switcher (NEW Component)

#### 4.2.1 Visual Design

```
┌──────────────────────┐
│ Acme Corp        ▼  │  ← Dropdown trigger
└──────────────────────┘
```

**Dropdown Menu**:
```
┌─────────────────────────────┐
│ YOUR ORGANIZATIONS          │
├─────────────────────────────┤
│ ✓ Acme Corp                 │  ← Current (checkmark)
│   Tech Startup Inc          │
│   Default Organization      │
├─────────────────────────────┤
│ + Create Organization       │  ← Future feature
│ ⚙ Manage Organizations      │  ← Future feature
└─────────────────────────────┘
```

#### 4.2.2 Behavior

**On Click**:
1. Show dropdown with user's organizations
2. Highlight current organization
3. Click on different org → Redirect to that org's dashboard
4. Preserve current section if possible (e.g., if on Testing, go to new org's Testing)

**URL Structure**:
- Current: `/orgs/acme-corp/app/testing`
- Switch to "tech-startup" → `/orgs/tech-startup/app/testing`

**Edge Cases**:
- User has only 1 organization → Still show switcher (for consistency)
- User has 0 organizations → Redirect to "Create Organization" flow
- User tries to access org they don't belong to → 404 or redirect to their first org

#### 4.2.3 Technical Implementation

**Component**: `app/views/shared/_organization_switcher.html.erb`

**Data Source**: `current_user.organizations` (via `ActsAsTenant.without_tenant`)

**Current Organization**: `ActsAsTenant.current_tenant` or `@current_organization`

---

### 4.3 User Menu (NEW Component)

#### 4.3.1 Visual Design

```
┌──────────────────┐
│ DG           ▼  │  ← User initials + dropdown
└──────────────────┘
```

**Dropdown Menu**:
```
┌─────────────────────────────┐
│ David Geismar               │  ← Full name
│ admin@example.com           │  ← Email
├─────────────────────────────┤
│ 👤 Profile                  │
│ ⚙️  Account Settings        │
│ 🔑 API Keys (current org)   │  ← Context-aware
├─────────────────────────────┤
│ 🚪 Sign Out                 │
└─────────────────────────────┘
```

#### 4.3.2 Menu Items

1. **Profile** (Future)
   - Links to: `/profile` or `/users/:id`
   - Shows: User info, activity, stats

2. **Account Settings**
   - Links to: `/users/edit` (Devise edit registration)
   - Shows: Edit email, password, profile info

3. **API Keys** (Context-aware)
   - Only shown when in organization context
   - Links to: `/orgs/:org_slug/api_keys`
   - Quick access to current org's API keys

4. **Sign Out**
   - Links to: `destroy_user_session_path` (Devise)
   - Method: DELETE
   - Redirects to: Landing page

#### 4.3.3 User Avatar/Initials

**Display Logic**:
1. If user has avatar → Show avatar image
2. Else → Show initials (first letter of first name + last name)
3. Background color: Generated from user ID (consistent color per user)

**Example**:
- "David Geismar" → "DG"
- "John Doe" → "JD"

---

### 4.4 Layout Override Strategy

#### 4.4.1 File Structure

**Host App Layout**:
```
app/views/layouts/
├── application.html.erb          # Main host app layout
└── prompt_tracker/
    └── application.html.erb      # Override engine layout
```

**Shared Partials**:
```
app/views/shared/
├── _navbar.html.erb              # Unified navigation bar
├── _organization_switcher.html.erb
├── _user_menu.html.erb
├── _flash_messages.html.erb
└── _breadcrumbs.html.erb
```

#### 4.4.2 Layout Override Implementation

**File**: `app/views/layouts/prompt_tracker/application.html.erb`

**Strategy**: Render host app layout with PromptTracker-specific content

```erb
<%# Override PromptTracker's layout to use host app's unified navigation %>

<% content_for :page_title, "PromptTracker" %>

<% content_for :breadcrumbs do %>
  <%# PromptTracker pages can add their own breadcrumbs %>
  <%= yield :breadcrumbs %>
<% end %>

<%# Render the host app's main layout %>
<%= render template: "layouts/application" %>
```

**Result**: PromptTracker pages now use host app's navbar, organization switcher, user menu, etc.

#### 4.4.3 Preserving PromptTracker Features

**Features to Preserve**:
1. ✅ Theme toggle (light/dark mode)
2. ✅ Search bar
3. ✅ Testing/Monitoring navigation
4. ✅ Breadcrumbs
5. ✅ Footer with stats
6. ✅ Chart.js configuration
7. ✅ JetBrains Mono font

**How to Preserve**:
- Copy PromptTracker's navbar structure into host app's `_navbar.html.erb`
- Include PromptTracker's JavaScript for theme toggle
- Include PromptTracker's CSS for navbar styling
- Keep footer in PromptTracker views (not in layout)

---

### 4.5 Landing Page (Public)

#### 4.5.1 Layout

**File**: `app/views/home/index.html.erb`

**Sections**:
1. Hero
2. Features
3. Use Cases
4. How It Works
5. Pricing/CTA
6. Footer

#### 4.5.2 Hero Section

**Content**:
```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│         >PromptTracker                                  │
│                                                         │
│    Enterprise-Grade Prompt Management                  │
│         & LLM Tracking Platform                        │
│                                                         │
│   Version, test, and monitor your LLM prompts          │
│        with confidence and precision                   │
│                                                         │
│   [Get Started Free]  [View Demo]                      │
│                                                         │
│   [Screenshot of dashboard]                            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Elements**:
- **Logo**: `>PromptTracker` (same branding)
- **Headline**: Clear value proposition
- **Subheadline**: 1-2 sentence explanation
- **CTA Buttons**:
  - Primary: "Get Started Free" → Sign Up
  - Secondary: "View Demo" → Demo video or tour
- **Hero Image**: Screenshot of PromptTracker dashboard

**Design**:
- Background: Gradient (dark blue to electric blue)
- Text: White
- Buttons: Electric blue (primary), outline (secondary)
- Height: 100vh (full screen)

#### 4.5.3 Features Section

**Grid Layout**: 3 columns × 2 rows (6 features)

**Features**:
1. **📝 Prompt Versioning**
   - Track every change to your prompts
   - Git-like version control for LLM prompts

2. **📊 LLM Analytics**
   - Monitor costs, latency, and quality
   - Real-time dashboards and insights

3. **🧪 Automated Testing**
   - Evaluate prompts against datasets
   - Regression testing for prompt changes

4. **🔬 A/B Testing**
   - Compare prompt variations
   - Data-driven prompt optimization

5. **🔑 Multi-Provider Support**
   - OpenAI, Anthropic, Google, Azure
   - Unified interface for all providers

6. **👥 Team Collaboration**
   - Work together on prompts
   - Role-based access control

**Card Design**:
- Icon (large, colored)
- Title (bold)
- Description (2-3 lines)
- "Learn More" link
#### 4.5.4 Use Cases Section

**Layout**: 3 columns

**Use Cases**:
1. **For Developers**
   - Iterate faster on prompts
   - Test changes before production
   - Track performance over time

2. **For Teams**
   - Collaborate on prompt engineering
   - Share best practices
   - Maintain prompt library

3. **For Enterprises**
   - Governance and compliance
   - Cost control and monitoring
   - Audit trail for all changes

#### 4.5.5 How It Works Section

**Steps** (4-step process):
1. **Connect Your LLM Providers** - Add API keys for OpenAI, Anthropic, etc.
2. **Create & Version Prompts** - Build prompts with variables and versioning
3. **Test & Evaluate** - Run automated tests against datasets
4. **Monitor & Optimize** - Track performance and iterate

**Visual**: Diagram or screenshots showing each step

#### 4.5.6 Pricing/CTA Section

**Content**:
- **Headline**: "Ready to get started?"
- **Subheadline**: "Start managing your prompts like a pro"
- **CTA Button**: "Get Started Free"
- **Note**: "No credit card required" or "Contact us for pricing"

**Design**:
- Background: Light gray or white
- CTA button: Large, electric blue
- Center-aligned

#### 4.5.7 Footer

**Content**:
- **Left**: Copyright, PromptTracker branding
- **Center**: Links (About, Documentation, Terms, Privacy)
- **Right**: Social links (GitHub, Twitter, etc.)

---

### 4.6 Devise Views Customization

#### 4.6.1 Generate Devise Views

**Command**:
```bash
rails generate devise:views
```

**Files Created**:
- `app/views/devise/sessions/new.html.erb` - Sign In
- `app/views/devise/registrations/new.html.erb` - Sign Up
- `app/views/devise/registrations/edit.html.erb` - Edit Account
- `app/views/devise/passwords/new.html.erb` - Forgot Password
- `app/views/devise/passwords/edit.html.erb` - Reset Password
- `app/views/devise/confirmations/new.html.erb` - Resend Confirmation
- `app/views/devise/unlocks/new.html.erb` - Unlock Account
- `app/views/devise/shared/_links.html.erb` - Shared links

#### 4.6.2 Sign In Page (`devise/sessions/new.html.erb`)

**Layout**:
```
┌─────────────────────────────────┐
│                                 │
│      >PromptTracker             │
│                                 │
│      Sign In                    │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Email                     │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Password                  │  │
│  └───────────────────────────┘  │
│                                 │
│  ☐ Remember me                  │
│                                 │
│  [Sign In]                      │
│                                 │
│  Forgot password?               │
│  Don't have an account? Sign up │
│                                 │
└─────────────────────────────────┘
```

**Design**:
- Centered card (max-width: 400px)
- Bootstrap form styling
- Electric blue submit button
- Links styled consistently

#### 4.6.3 Sign Up Page (`devise/registrations/new.html.erb`)

**Layout**:
```
┌─────────────────────────────────┐
│                                 │
│      >PromptTracker             │
│                                 │
│      Create Account             │
│                                 │
│  ┌───────────────────────────┐  │
│  │ First Name                │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Last Name                 │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Email                     │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Password                  │  │
│  └───────────────────────────┘  │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Confirm Password          │  │
│  └───────────────────────────┘  │
│                                 │
│  ☐ I agree to Terms of Service  │
│                                 │
│  [Create Account]               │
│                                 │
│  Already have an account?       │
│  Sign in                        │
│                                 │
└─────────────────────────────────┘
```

**Fields**:
- First Name (required)
- Last Name (required)
- Email (required)
- Password (required, min 6 chars)
- Password Confirmation (required)
- Terms acceptance checkbox (required)

**Post-Signup Flow**:
1. Create user account
2. Send confirmation email (if confirmable enabled)
3. Create default organization for user
4. Redirect to organization dashboard or onboarding

#### 4.6.4 Account Settings (`devise/registrations/edit.html.erb`)

**Sections**:
1. **Profile Information**
   - First Name
   - Last Name
   - Email (with reconfirmation if changed)

2. **Change Password**
   - Current Password
   - New Password
   - Confirm New Password

3. **Danger Zone**
   - Delete Account (with confirmation modal)

**Design**:
- Full-width form (max-width: 600px)
- Sections separated by horizontal rules
- Delete button in red

#### 4.6.5 Forgot Password (`devise/passwords/new.html.erb`)

**Layout**:
```
┌─────────────────────────────────┐
│                                 │
│      >PromptTracker             │
│                                 │
│      Reset Password             │
│                                 │
│  Enter your email address and   │
│  we'll send you a link to       │
│  reset your password.           │
│                                 │
│  ┌───────────────────────────┐  │
│  │ Email                     │  │
│  └───────────────────────────┘  │
│                                 │
│  [Send Reset Link]              │
│                                 │
│  Back to Sign In                │
│                                 │
└─────────────────────────────────┘
```

#### 4.6.6 Design Consistency

**All Devise Views Should Have**:
- ✅ PromptTracker logo at top
- ✅ Centered card layout
- ✅ Bootstrap form styling
- ✅ Consistent button colors (electric blue)
- ✅ Helpful error messages
- ✅ Clear labels and placeholders
- ✅ Responsive design
- ✅ Links to other auth pages

---

### 4.7 Flash Messages

#### 4.7.1 Component

**File**: `app/views/shared/_flash_messages.html.erb`

**Flash Types**:
- `success` → Green alert
- `error` → Red alert
- `alert` → Yellow alert
- `notice` → Blue alert

**Design**:
- Bootstrap alerts
- Auto-dismiss after 5 seconds (optional)
- Close button (×)
- Positioned below navbar

**Example**:
```erb
<% flash.each do |type, message| %>
  <div class="alert alert-<%= bootstrap_class_for(type) %> alert-dismissible fade show" role="alert">
    <%= message %>
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  </div>
<% end %>
```

---

### 4.8 Breadcrumbs

#### 4.8.1 Component

**File**: `app/views/shared/_breadcrumbs.html.erb`

**Usage**:
```erb
<% content_for :breadcrumbs do %>
  <li class="breadcrumb-item"><%= link_to "Prompts", prompts_path %></li>
  <li class="breadcrumb-item active">New Prompt</li>
<% end %>
```

**Rendering**:
```erb
<% if content_for?(:breadcrumbs) %>
  <nav aria-label="breadcrumb">
    <ol class="breadcrumb">
      <li class="breadcrumb-item"><%= link_to "Home", root_path %></li>
      <%= yield :breadcrumbs %>
    </ol>
  </nav>
<% end %>
```

**Design**:
- Bootstrap breadcrumbs
- Positioned below navbar
- Auto-includes "Home" as first item
- Current page is not a link (active state)

---

## 5. Technical Implementation Plan

### 5.1 Phase 1: Core Layout & Navigation (Priority 1)

**Tasks**:
1. ✅ Create `app/views/shared/_navbar.html.erb`
   - Copy PromptTracker navbar structure
   - Add organization switcher placeholder
   - Add user menu placeholder
   - Add guest state (Sign In/Sign Up buttons)

2. ✅ Create `app/views/shared/_organization_switcher.html.erb`
   - Dropdown with user's organizations
   - Current organization highlighted
   - Switch organization functionality

3. ✅ Create `app/views/shared/_user_menu.html.erb`
   - User initials/avatar
   - Dropdown menu
   - Sign out link

4. ✅ Create `app/views/shared/_flash_messages.html.erb`
   - Bootstrap alerts
   - Auto-dismiss functionality

5. ✅ Update `app/views/layouts/application.html.erb`
   - Include navbar partial
   - Include flash messages
   - Add breadcrumbs support
   - Include PromptTracker CSS/JS

6. ✅ Create `app/views/layouts/prompt_tracker/application.html.erb`
   - Override engine layout
   - Render host app layout

**Deliverables**:
- Unified navigation working across host app and engine
- Organization switcher functional
- User menu functional
- Flash messages styled

**Testing**:
- Navigate between host app and PromptTracker
- Switch organizations
- Sign in/out
- Flash messages display correctly

---

### 5.2 Phase 2: Landing Page (Priority 2)

**Tasks**:
1. ✅ Update `app/views/home/index.html.erb`
   - Hero section
   - Features section
   - Use cases section
   - How it works section
   - Pricing/CTA section
   - Footer

2. ✅ Add custom CSS for landing page
   - Hero gradient background
   - Feature cards
   - Responsive layout

**Deliverables**:
- Professional landing page
- Responsive design
- Clear CTAs

**Testing**:
- View on desktop, tablet, mobile
- Click all CTAs
- Check load time (<2s)

---

### 5.3 Phase 3: Devise Views (Priority 3)

**Tasks**:
1. ✅ Generate Devise views: `rails generate devise:views`

2. ✅ Customize each view:
   - Sign In
   - Sign Up
   - Edit Account
   - Forgot Password
   - Reset Password
   - Confirmation
   - Unlock

3. ✅ Add Bootstrap styling to all forms

4. ✅ Add PromptTracker branding to all pages

**Deliverables**:
- Branded Devise views
- Consistent design
- Better UX

**Testing**:
- Sign up flow
- Sign in flow
- Password reset flow
- Account editing

---

### 5.4 Phase 4: Polish & Refinement (Priority 4)

**Tasks**:
1. ✅ Add breadcrumbs to key pages
2. ✅ Improve mobile responsiveness
3. ✅ Add loading states
4. ✅ Add error states
5. ✅ Accessibility improvements (ARIA labels, keyboard navigation)
6. ✅ Performance optimization

**Deliverables**:
- Polished, production-ready UI
- Accessible
- Fast

---

## 6. Design System

### 6.1 Colors (from PromptTracker)

**Primary Colors**:
- Electric Blue: `#007BFF`
- Neon Green: `#00D97E`
- Dark Background: `#1a1a1a`
- Light Background: `#ffffff`

**Semantic Colors**:
- Success: `#00D97E` (green)
- Warning: `#FFC107` (yellow)
- Danger: `#DC3545` (red)
- Info: `#17A2B8` (cyan)

**Text Colors**:
- Dark mode: `#E5E7EB`
- Light mode: `#212529`

### 6.2 Typography

**Font Family**: JetBrains Mono (monospace)
- Headings: 600-700 weight
- Body: 400 weight
- Code: 300 weight

**Font Sizes**:
- H1: 2.5rem
- H2: 2rem
- H3: 1.75rem
- H4: 1.5rem
- Body: 1rem
- Small: 0.875rem

### 6.3 Spacing

**Bootstrap Spacing Scale**:
- 0: 0
- 1: 0.25rem (4px)
- 2: 0.5rem (8px)
- 3: 1rem (16px)
- 4: 1.5rem (24px)
- 5: 3rem (48px)

### 6.4 Components

**Buttons**:
- Primary: Electric blue background, white text
- Secondary: Outline, electric blue border
- Danger: Red background, white text

**Cards**:
- Border: 1px solid #dee2e6
- Border radius: 0.25rem
- Padding: 1.5rem
- Shadow: 0 0.125rem 0.25rem rgba(0,0,0,0.075)

**Forms**:
- Input height: 38px
- Border: 1px solid #ced4da
- Border radius: 0.25rem
- Focus: Electric blue border

---

## 7. File Checklist

### 7.1 New Files to Create

**Layouts**:
- [ ] `app/views/layouts/prompt_tracker/application.html.erb`

**Shared Partials**:
- [ ] `app/views/shared/_navbar.html.erb`
- [ ] `app/views/shared/_organization_switcher.html.erb`
- [ ] `app/views/shared/_user_menu.html.erb`
- [ ] `app/views/shared/_flash_messages.html.erb`
- [ ] `app/views/shared/_breadcrumbs.html.erb`

**Devise Views** (generated + customized):
- [ ] `app/views/devise/sessions/new.html.erb`
- [ ] `app/views/devise/registrations/new.html.erb`
- [ ] `app/views/devise/registrations/edit.html.erb`
- [ ] `app/views/devise/passwords/new.html.erb`
- [ ] `app/views/devise/passwords/edit.html.erb`
- [ ] `app/views/devise/confirmations/new.html.erb`
- [ ] `app/views/devise/unlocks/new.html.erb`
- [ ] `app/views/devise/shared/_links.html.erb`

**Helpers** (optional):
- [ ] `app/helpers/navigation_helper.rb` - Helper methods for navigation

**JavaScript** (optional):
- [ ] `app/javascript/controllers/organization_switcher_controller.js` - Stimulus controller
- [ ] `app/javascript/controllers/theme_toggle_controller.js` - Theme toggle

**CSS**:
- [ ] Custom styles in `app/assets/stylesheets/application.bootstrap.scss`

### 7.2 Files to Modify

- [ ] `app/views/layouts/application.html.erb` - Add navbar, flash, breadcrumbs
- [ ] `app/views/home/index.html.erb` - Build landing page
- [ ] `app/assets/stylesheets/application.bootstrap.scss` - Add custom styles
- [ ] `app/controllers/application_controller.rb` - Add helper methods (if needed)

---

## 8. Success Criteria

### 8.1 Functional Requirements

- ✅ Users can navigate between host app and PromptTracker seamlessly
- ✅ Organization switcher works and preserves current section
- ✅ User menu shows correct user info and links
- ✅ Sign in/out works correctly
- ✅ Flash messages display and dismiss properly
- ✅ Breadcrumbs show current location
- ✅ Landing page loads in <2s
- ✅ All Devise flows work (sign up, sign in, password reset, etc.)
- ✅ Mobile responsive (works on all screen sizes)

### 8.2 Design Requirements

- ✅ Consistent branding across all pages
- ✅ PromptTracker logo and colors used throughout
- ✅ Bootstrap 5.3.0 styling
- ✅ JetBrains Mono font
- ✅ Theme toggle works (light/dark mode)
- ✅ Professional, modern design
- ✅ Accessible (ARIA labels, keyboard navigation)

### 8.3 User Experience

- ✅ Users don't feel like they're switching between apps
- ✅ Current organization always visible
- ✅ Easy to switch organizations
- ✅ Clear navigation structure
- ✅ Helpful error messages
- ✅ Fast page loads
- ✅ Smooth transitions

---

## 9. Open Questions & Decisions Needed

### 9.1 Organization Creation

**Question**: When should users create their first organization?

**Options**:
1. **During sign-up** - Create default organization automatically
2. **After sign-up** - Redirect to "Create Organization" page
3. **On-demand** - Create when first accessing PromptTracker

**Recommendation**: Option 1 - Create default organization automatically during sign-up for smoother onboarding.

### 9.2 Organization Naming

**Question**: What should the default organization be named?

**Options**:
1. "Personal Workspace"
2. "{User's Name}'s Organization"
3. "Default Organization"
4. Let user choose during sign-up

**Recommendation**: Option 2 - "{User's Name}'s Organization" feels more personal.

### 9.3 Footer Placement

**Question**: Should the footer be in the layout or in individual views?

**Options**:
1. **In layout** - Shows on every page
2. **In views** - Only on landing page and public pages

**Recommendation**: Option 2 - Footer only on public pages. Authenticated pages don't need footer (more space for content).

### 9.4 Theme Toggle Persistence

**Question**: Should theme preference be stored in database or localStorage?

**Options**:
1. **localStorage** - Client-side only (current PromptTracker approach)
2. **Database** - Synced across devices
3. **Both** - Database with localStorage fallback

**Recommendation**: Option 1 for now (localStorage), upgrade to Option 3 later for better UX.

---

## 10. Timeline Estimate

**Total Estimated Time**: 12-16 hours

**Breakdown**:
- Phase 1 (Core Layout & Navigation): 4-5 hours
- Phase 2 (Landing Page): 3-4 hours
- Phase 3 (Devise Views): 3-4 hours
- Phase 4 (Polish & Refinement): 2-3 hours

**Dependencies**:
- None (can start immediately)

**Risks**:
- PromptTracker CSS conflicts with host app CSS
- Theme toggle JavaScript conflicts
- Responsive design edge cases

**Mitigation**:
- Test thoroughly on different screen sizes
- Use CSS namespacing if conflicts arise
- Follow PromptTracker's existing patterns

---

## 11. Appendix

### 11.1 PromptTracker Navbar HTML Structure

```html
<nav class="navbar navbar-expand-lg navbar-dark pt-navbar">
  <div class="container-fluid">
    <a href="/" class="navbar-brand pt-brand">
      <span class="pt-logo-cursor">&gt;</span>
      <span class="pt-logo-prompt">Prompt</span>
      <span class="pt-logo-tracker">Tracker</span>
    </a>

    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
      <span class="navbar-toggler-icon"></span>
    </button>

    <div class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav me-auto">
        <li class="nav-item">
          <a href="/testing" class="nav-link">
            <i class="bi bi-check2-square"></i> Testing
          </a>
        </li>
        <li class="nav-item">
          <a href="/monitoring" class="nav-link pt-nav-monitoring">
            <i class="bi bi-activity"></i> Monitoring
          </a>
        </li>
      </ul>

      <form class="d-flex" role="search">
        <input class="form-control me-2" type="search" placeholder="Search prompts...">
        <button class="btn btn-outline-primary" type="submit">
          <i class="bi bi-search"></i>
        </button>
      </form>

      <button class="theme-toggle ms-3" id="themeToggle">
        <i class="bi bi-sun-fill" id="themeIcon"></i>
      </button>
    </div>
  </div>
</nav>
```

### 11.2 Helper Method Examples

```ruby
# app/helpers/navigation_helper.rb
module NavigationHelper
  def user_initials(user)
    "#{user.first_name[0]}#{user.last_name[0]}".upcase
  end

  def user_avatar_color(user)
    colors = ['#007BFF', '#00D97E', '#FFC107', '#DC3545', '#17A2B8']
    colors[user.id % colors.length]
  end

  def bootstrap_class_for(flash_type)
    case flash_type.to_sym
    when :success then 'success'
    when :error then 'danger'
    when :alert then 'warning'
    when :notice then 'info'
    else flash_type.to_s
    end
  end

  def current_section
    if controller_path.start_with?('prompt_tracker/testing')
      'testing'
    elsif controller_path.start_with?('prompt_tracker/monitoring')
      'monitoring'
    else
      'home'
    end
  end
end
```

---

**End of PRD**
