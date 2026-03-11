# BeTogether Project Specification

## Future Features

### Apple Sign-In Integration (Postponed)
This feature has been postponed due to Apple Developer Program fee requirements.

**1. Required Setup (Apple & Supabase)**
- **Apple Developer Portal:**
  - Need to enroll in Apple Developer Program (requires fee).
  - Enable "Sign In with Apple" capability on the App ID (`com.wnsghl6272.BeTogether`).
  - Create a new Service ID for "Sign In with Apple".
  - Generate a new Private Key (`.p8` file) for "Sign In with Apple".
- **Supabase Dashboard:**
  - Go to Authentication > Providers > Apple.
  - Turn on the toggle.
  - Fill in Bundle ID, Team ID, Key ID, and the `.p8` Private Key content.
- **Xcode Project:**
  - Add "Sign In with Apple" capability in Signing & Capabilities.

**2. User Management & Onboarding Flow Considerations**
- Apple Sign-In provides an email (often a private relay email) but **DOES NOT provide a phone number**.
- **Recommended Flow (Option A):** 
  - Since our app relies heavily on phone numbers (e.g., for Contact Blocking), the onboarding flow for Apple users should look like this:
  - Apple Login -> **Phone Number Verification** -> Terms View -> Profile Setup
- This skips the Email Verification step (as Apple verifies the email), but enforces Phone Verification to maintain data consistency and enable features like blocking contacts.
