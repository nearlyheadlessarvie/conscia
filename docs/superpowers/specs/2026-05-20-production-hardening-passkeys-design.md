# Production Hardening, Family Invite Email, and Cognito Passkeys Design

## Summary

This pass closes the production gaps that currently allow fake or placeholder behavior to leak into real releases, adds reliable family invite delivery with app deep links, and replaces the current faux biometric sign-in with real Cognito-native passkeys for Conscia accounts.

The work is intentionally split into two auth lanes:

- Cognito lane: email/password plus passkeys for Conscia-native accounts
- App-auth lane: native Google and Apple sign-in remain as-is for first release

This keeps the flagship passkey experience without forcing browser-based federation into the first release.

## Goals

- Fail closed for integrations that should never silently degrade in production
- Ensure deployed API environments receive the runtime secrets and config they actually need
- Deliver family invites by email with a deep link into the app
- Keep in-app alerts and push notifications for existing users where available
- Remove the current local-auth biometric shim
- Introduce real passkey enrollment and sign-in for Cognito-native users

## Non-Goals

- Replacing Google or Apple native sign-in with Cognito-hosted federation
- Introducing dynamic storage for Conscience Journey rules
- Implementing browser-based passkey UX
- Building a fully unified account-linking story between passkey and social accounts in this pass

## Current Problems

### 1. Store validation fails open

Subscription verification currently grants Premium even when Apple or Google server-side validation is not configured.

### 2. API runtime wiring is incomplete

The deployed Lambda stack does not inject the auth and store-validation settings the API expects, so production deploys can look configured while critical features are still dead.

### 3. Receipt OCR is still stubbed

Receipt scan persists placeholder OCR/parsing output instead of using a real production OCR pipeline.

### 4. Push delivery is a no-op

Push notifications are scaffolded but the runtime sender still only logs and exits.

### 5. Infra throttling drifted after query-string versioning

API Gateway throttling rules still target old `/api/v1/...` paths instead of the current `/api/...` routes.

### 6. Family invites are not reliably delivered

Invites create records and can surface as in-app alerts for existing users, but unregistered or inactive users do not receive a real email invite path.

### 7. Current biometric sign-in is not a real auth feature

The app currently uses local biometrics only to unlock reuse of stored local session state. That is not a true provider-backed or Cognito-backed biometric sign-in flow and should not ship as a flagship auth feature.

## Design

## A. Fail-Closed Production Hardening

### Subscriptions

Receipt verification endpoints must reject verification attempts when the corresponding validator is not configured.

Behavior:

- iOS verification returns a clear error when Apple validation is not configured
- Android verification returns a clear error when Google Play validation is not configured
- no fallback grace subscription is created
- logs should identify configuration failure separately from invalid user receipts

This applies in all deployed environments. Local development can still opt into mock-friendly behavior only if explicitly configured in a development-only path, not through production defaults.

### Receipt Scan

Receipt scan must be unavailable unless a real OCR implementation is configured.

Behavior:

- if OCR is not configured, `/api/receipts/scan?v=1` returns a clear server-side configuration error
- the app shows a user-friendly unavailable message instead of pretending extraction worked
- placeholder extraction text or fake parsed receipt results must never be persisted in production

### Push Delivery

Push notifications must not pretend to be active when no sender is configured.

Behavior:

- if push delivery is disabled, device token registration can remain optional but delivery paths must clearly no-op by policy rather than masquerading as configured
- if the product surface claims push is enabled, runtime must have a concrete sender implementation configured
- server-side configuration should make the active push mode explicit

### Runtime Secret Validation

The API should fail startup in production when required auth/runtime settings are missing.

Required production validations:

- Cognito user pool and client settings
- app JWT signing key when app-issued JWT auth is enabled
- Google token audience for Google sign-in verification
- Apple token audience for Apple sign-in verification
- App Compatibility config
- store-validation secrets when verification endpoints are enabled
- OCR configuration when receipt scan is enabled

The exact validator can be implemented as startup validation over options/configuration sections.

### Infra Wiring

CDK must inject the real runtime config into Lambda instead of relying on blank `appsettings.json` placeholders.

The target model is:

- GitHub Actions uses deploy-time secrets and variables
- release workflows pass required values to CDK
- CDK injects those values into Lambda environment variables
- production Lambda starts only when required values are present

This pass does not require a full migration to Secrets Manager or SSM, but the wiring must be explicit and correct.

### API Gateway Throttling

Special throttling rules must be updated from `/api/v1/...` to the current `/api/...` route set so rate limits still apply to the intended endpoints.

## B. Family Invite Email and Deep Link

Family invites should be delivered through three channels depending on user state:

1. Email invite with deep link
2. In-app alert for known users
3. Push notification for known users when push delivery is configured

### Invite Creation

When a family invite is created:

- always create the invite record
- always create an outbox event
- outbox processing attempts email delivery for the invite target
- if the target email belongs to an existing user, also create the in-app alert
- if push is configured, also attempt push delivery for existing users

### Deep Link

The invite email should link users into the app’s family invites screen.

Target route:

- app route: `/settings/family-space/invites`

The deep-link strategy should support mobile app opening first and still degrade gracefully if the app is not yet installed.

Practical first-release recommendation:

- use an HTTPS app link / universal link on the Conscia domain
- that link resolves into the app route
- if the app is not installed, it can land on a simple web fallback page later

For this pass, the critical requirement is that the app can open directly into the invites screen from the emailed link.

### Email Content

The email should include:

- family space name
- invited role
- expiry timing
- clear CTA to open Conscia and review the invite

We do not need one-click accept from email in this pass. Accept and decline remain authenticated in-app actions.

## C. Cognito Passkeys for Conscia Accounts

### Product Model

Passkeys become a flagship sign-in method for Conscia-native accounts only.

Supported in this pass:

- Cognito email/password sign-up
- Cognito email/password sign-in
- passkey enrollment after sign-in
- passkey sign-in for enrolled Cognito-native accounts

Not supported in this pass:

- passkeys for Google-native accounts
- passkeys for Apple-native accounts
- account linking between social and Cognito-native identities

### Side-by-Side With Existing Auth

Auth remains split into two lanes:

#### Cognito Lane

- email/password
- passkeys
- Cognito issues and refreshes tokens

#### App-Auth Lane

- native Google sign-in
- native Apple sign-in
- backend verifies provider tokens and issues app session tokens

This avoids forcing browser-based Cognito federation for Google/Apple in first release while still delivering a real flagship passkey experience.

### Why Passkeys Instead of Local Biometrics

The current local-auth flow is only a device gate in front of stored local session tokens. It is not a first-class auth method.

Passkeys are the correct flagship experience because:

- they are provider-backed and account-bound
- they use platform biometric/user-presence UX
- they do not depend on pretending a local refresh path is a biometric identity feature

### Enrollment Flow

For a Cognito-authenticated user:

1. User signs in with email/password
2. User opens the passkey enrollment action in settings
3. App initiates Cognito passkey registration flow
4. Platform passkey UI handles Face ID / fingerprint / passkey creation
5. Cognito records the passkey against that user
6. UI reflects that passkey sign-in is now enabled

### Sign-In Flow

For a Cognito-native account with a registered passkey:

1. User chooses passkey sign-in from the sign-in screen
2. App initiates Cognito passkey authentication
3. Platform passkey UI challenges the user
4. Cognito validates the passkey assertion
5. Cognito returns session tokens
6. App continues through the existing authenticated path

### App UX Changes

The current biometric toggle and “Sign in with Biometrics” button should be removed.

Replace with:

- settings action for `Set up Passkey` or `Manage Passkey`
- sign-in action for `Sign in with Passkey`

Copy must clearly distinguish passkeys from Apple sign-in and from password login.

### Technical Constraint

Although WebAuthn originated as a browser API, mobile passkeys are supported through platform-native capabilities used by apps. The app will need a Flutter-compatible integration path that works with Cognito’s passkey challenge flow and the required relying-party domain/app association setup.

The implementation should validate feasibility against the actual Cognito mobile passkey flow before deeply coupling UI to any one plugin abstraction.

## Error Handling

- Missing production config should produce explicit startup failures, not silent downgrades
- Invite email failure should not destroy the invite record, but should leave the event retryable or observable
- In-app alert and push remain best-effort side effects after invite record creation
- Passkey enrollment failures should never break existing password sign-in
- Passkey sign-in failure should fall back to normal sign-in options

## Testing Strategy

### Backend

- startup/config validation tests
- subscription verification tests for unconfigured vs configured behavior
- receipt scan tests for disabled vs configured OCR behavior
- invite outbox processing tests for:
  - existing user
  - unregistered user
  - email dispatch
  - in-app alert creation
- throttling template assertions in infra tests

### App

- sign-in screen tests for passkey UI and removal of faux biometric UI
- settings tests for passkey enrollment action and removal of biometric toggle
- deep-link routing test into family invites screen
- invite acceptance flow tests from routed screen state

### Deployment

- release workflow checks for required runtime secret propagation
- CDK synth/deploy assertions for Lambda environment variables

## Rollout Order

1. Hardening and fail-closed behavior
2. Runtime secret/config wiring through deploy workflows and CDK
3. Family invite email plus deep link
4. Remove faux biometric sign-in
5. Add Cognito passkey enrollment and sign-in

This ordering prevents fake behavior from surviving into the first release while still landing passkeys in the same overall initiative.
