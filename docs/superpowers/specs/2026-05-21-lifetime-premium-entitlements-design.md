# Lifetime Premium Entitlements Design

## Goal

Add backend-owned lifetime premium entitlements for specific users, keyed by user ID, so Conscia can comp premium access without app-side hardcoded emails or store receipts.

## Scope

This design covers:

- a durable backend entitlement override record for lifetime premium grants
- effective subscription status resolution that merges normal subscription state with overrides
- a protected admin API to grant and revoke lifetime premium by user ID
- a bootstrap admin flow that does not require manual Dynamo editing or pre-seeded Cognito subject IDs
- a minimal internal admin page for repeated entitlement operations and reviewer/demo account support
- a seed path that writes the same backend-owned override data for local or controlled environments
- tests for the service layer, API behavior, and seed behavior
- release-safe documentation for operators and developers

This design does not cover:

- a general-purpose RBAC or full admin console
- app-side admin UI
- broad user lifecycle management beyond narrow reviewer/demo provisioning
- additional entitlement types beyond lifetime premium
- changing store verification behavior for iOS or Android purchases

## Requirements

- The override source of truth must be a backend record keyed by user ID.
- Premium checks must honor lifetime overrides everywhere `ISubscriptionService.IsPremiumAsync` is used.
- `/api/subscriptions/status` must return effective status, not only raw store subscription data.
- Lifetime premium must remain distinct from paid subscriptions in the status payload.
- Admin grant and revoke behavior must use the same backend code path as seeded grants.
- Bootstrap admin authority must not depend on unknown pre-registration Cognito subject IDs.
- The implementation must avoid app-side hardcoded emails and avoid release-dangerous manual config edits as the primary workflow.

## Recommended Approach

Use a dedicated entitlement override record plus a merge layer inside the subscription service.

Why this approach:

- It keeps comped access explicit and separate from paid billing state.
- It allows the API to report an honest source such as `lifetime` or `store`.
- It avoids abusing the existing `UserSubscription` model with fake perpetual subscriptions.
- It keeps future entitlement expansion possible without committing to a broad entitlement system now.

Rejected alternatives:

- Writing fake perpetual `UserSubscription` rows would blur billing records and override intent.
- Reading user IDs from config would be operationally brittle and would not satisfy the admin-path requirement cleanly.

## Data Model

Add a new backend record for lifetime premium entitlement overrides.

Suggested fields:

- `UserId`
- `EntitlementKey`
- `GrantedAt`
- `GrantedBy`
- `Note`

Constraints:

- `EntitlementKey` can be fixed to a single known value for now, such as `premium_lifetime`.
- Only one active lifetime premium override should exist per user.
- Granting the same override twice should be idempotent.
- Revocation should remove or deactivate the override in a way the service can evaluate deterministically.

Repository expectations:

- fetch override by user ID
- upsert grant by user ID
- revoke by user ID

The repository should follow current Dynamo-backed repository conventions already used in the backend.

## Effective Subscription Status

The subscription service should stop treating raw `UserSubscription` as the only status source.

Instead, it should compute an effective status from two inputs:

1. Lifetime premium override for the user
2. Latest store subscription for the user

Resolution rules:

1. If a lifetime premium override exists, the user is premium.
2. If no lifetime override exists and the latest store subscription is active, the user is premium.
3. Otherwise, the user is free.

Status precedence:

- Lifetime override takes precedence for status representation.
- Paid subscriptions remain stored and queryable, but the effective status response should report `source = lifetime` when both are present.

Suggested effective payload fields:

- `tier`
- `isActive`
- `isLifetime`
- `source`
- `platform`
- `expiresAt`

Field rules:

- Lifetime users: `tier = Premium`, `isActive = true`, `isLifetime = true`, `source = lifetime`, `expiresAt = null`
- Store premium users: preserve existing store data, `isLifetime = false`, `source = store`
- Free users: `tier = Free`, `isActive = false`, `isLifetime = false`, `source = none`

`ISubscriptionService.IsPremiumAsync` must rely on this merged effective status so all premium-gated endpoints honor the override automatically.

## API Design

### Subscription Status

Keep `GET /api/subscriptions/status`, but return effective status.

Expected behavior:

- lifetime-only user returns premium lifetime status
- paid-only user returns premium store status
- user with both returns premium lifetime status
- free user returns free status

The endpoint should remain backward-compatible enough for current clients by preserving `tier`, `isActive`, and `expiresAt`, while adding explicit lifetime/source fields.

### Admin Endpoints

Add a protected admin route group for entitlement overrides.

Suggested routes:

- `PUT /api/admin/entitlements/premium-lifetime/{userId}`
- `DELETE /api/admin/entitlements/premium-lifetime/{userId}`
- optional `GET /api/admin/entitlements/premium-lifetime/{userId}`

Suggested request body for grant:

- `grantedBy`
- `note`

The API should validate `userId` format and should return a clear not-found response if the target user does not exist.

Because the repo does not currently expose a full admin role model, this work should use a narrow protection mechanism scoped only to these endpoints. The protection should be implemented in a reusable backend pattern rather than as open endpoints or client-side assumptions.

Acceptable implementation shapes include:

- a dedicated internal shared-secret header validated server-side
- a dedicated authorization policy backed by internal identity claims if existing auth plumbing supports it cheaply

The important constraint is that admin entitlement writes are backend-protected and not available to ordinary authenticated users.

### Internal Admin Page

Add a very small internal admin page backed by the protected admin API.

Primary use cases:

- repeated lifetime premium grant and revoke actions by trusted operators
- quick lookup and verification of effective subscription status
- controlled provisioning for reviewer, demo, or test accounts used in App Store and Play review flows

Suggested capabilities:

- search or fetch a user by email and show the resolved user ID
- view effective subscription status for a user
- grant lifetime premium
- revoke lifetime premium
- create a narrow reviewer or demo account through a controlled provisioning action

Non-goals for this page:

- editing arbitrary user profile data
- password reset management
- full support tooling for all account operations
- broad role management

The admin page should remain a thin operator surface over backend-owned APIs. It must not become a second source of truth for entitlement state.

## Admin Bootstrap

Bootstrap admin authority should be separate from premium recipient storage.

Recommended model:

- keep premium recipients persisted in Dynamo entitlement override records keyed by user ID
- bootstrap a very small admin allowlist by trusted email in backend configuration
- on the admin's first successful Cognito-backed login, resolve the Cognito `sub` and persist admin authority by subject ID
- after bootstrap resolution, enforce admin access by persisted subject ID rather than email matching

Why this model:

- Cognito subject IDs are not known until the user exists
- it avoids pre-seeding real human accounts through infrastructure deployment
- it keeps the bootstrap surface narrow and separate from premium recipient logic
- it avoids weak shared secrets and avoids app-side hardcoded premium recipients

Operational flow:

1. A trusted team member is listed in the bootstrap admin email allowlist.
2. That user signs up normally.
3. On successful login, the backend sees the trusted email, records the user's Cognito `sub` as an authorized admin identity, and from then on uses subject-based admin checks.
4. That admin calls the protected entitlement endpoint for a target user ID.
5. The backend writes the lifetime premium entitlement override in Dynamo.

This bootstrap email allowlist is only for admin authority establishment. It is not the premium entitlement mechanism and must not be reused as a premium-recipient allowlist.

## Reviewer And Demo Accounts

App review and demo flows benefit from predictable, pre-created accounts rather than relying only on ad hoc signup and post-hoc granting.

Recommended model:

- allow narrow backend provisioning of reviewer or demo accounts for controlled use cases
- provision those users through Cognito-aware backend code rather than through infrastructure deployment templates
- grant lifetime premium to those provisioned accounts through the same entitlement override mechanism used for normal users

Why not infra-seed real reviewer users:

- human account data does not belong in infrastructure deployment definitions
- Cognito subjects are created as part of user provisioning, not static infra shape
- reviewer credentials and refresh cycles are better handled through operational tooling than release infrastructure

Provisioning scope should stay intentionally small:

- create a reviewer/demo account with email and initial delivery behavior
- ensure the local user record exists
- optionally grant lifetime premium immediately

The provisioning path should not attempt to become a general account-admin system.

## Seeder Path

Extend the existing seeding flow with a lifetime premium entitlement path that writes the same override record used by the admin API.

Rules:

- seed by user ID, not email
- use shared application/service code where practical so seed and admin behavior stay aligned
- keep seed reruns idempotent
- avoid creating fake store subscriptions for comped lifetime access

The seed path may support:

- adding lifetime premium to a curated demo or test user
- adding one or more known local IDs used in integration or smoke flows

The seed should remain explicit and opt-in where the surrounding seeder already prefers explicit profiles.

## Testing

### Unit Tests

Add subscription service tests for:

- lifetime override only returns premium effective status
- active store subscription returns premium store status
- inactive store subscription without override returns free status
- lifetime override plus active store subscription returns premium lifetime status
- `IsPremiumAsync` returns true for lifetime override users
- grant is idempotent
- revoke removes effective premium when there is no active paid subscription

### API Tests

Add endpoint tests for:

- `GET /api/subscriptions/status` returns lifetime metadata for override users
- premium-gated endpoints allow lifetime override users
- admin grant endpoint creates effective lifetime premium status
- admin revoke endpoint removes lifetime premium status
- admin endpoints reject unauthorized callers
- narrow provisioning endpoint creates reviewer/demo users without broad account-management behavior

### Admin Page Tests

Add focused tests for the internal admin page covering:

- authorized admin can look up a user and see the resolved user ID
- authorized admin can grant and revoke lifetime premium
- reviewer/demo provisioning path is visible and calls the backend correctly
- unauthorized users cannot access the page

### Seeder Tests

Add or extend tests so the seeder path:

- writes the lifetime override for the intended user ID
- is safe to rerun without duplicates
- does not depend on app-side email matching

## Documentation

Add short release-safe documentation covering:

- what lifetime premium entitlement overrides are
- that they are backend-owned and keyed by user ID
- how bootstrap admin authority works and why it is separate from premium recipient storage
- how to grant and revoke them through the protected admin path
- how the minimal internal admin page is intended to be used
- how reviewer/demo provisioning works and where its scope stops
- how to seed them locally or in controlled environments
- how they appear in `/api/subscriptions/status`

Documentation should avoid:

- advising manual store-record edits
- advising app-side hardcoded allowlists
- suggesting release tags or deploy steps beyond normal repo workflow

## Operational Notes

- This feature should be represented as a backend capability, not an app feature flag.
- It should not require a mobile app release to change which users are comped.
- The status payload should make it obvious whether premium access comes from billing or a lifetime override.
- Admin bootstrap should remain intentionally small and explicit. Do not generalize it into full RBAC in this change.
- The implementation should remain small and specific to lifetime premium. Do not generalize into a broad entitlement platform unless the code naturally needs one small shared abstraction.

## Operator Workflow

Expected real-world flow:

1. A future admin is listed in the bootstrap admin email allowlist.
2. That admin signs up and logs in normally, allowing the backend to persist admin authority by Cognito `sub`.
3. A premium recipient signs up and receives a normal user ID from Cognito.
4. The admin looks up the target user ID.
5. The admin calls the protected entitlement API to grant or revoke lifetime premium for that user ID.
6. The recipient's effective subscription status immediately resolves as premium with `source = lifetime`.

Reviewer/demo flow:

1. An authorized admin opens the internal admin page.
2. The admin provisions a narrow reviewer or demo account if needed.
3. The admin grants lifetime premium through the same backend entitlement API.
4. The reviewer or demo account can then be used in App Store or Play review instructions without manual Dynamo edits.

## Acceptance Criteria

- A backend record keyed by user ID can grant lifetime premium access.
- `ISubscriptionService.IsPremiumAsync` returns `true` for granted users.
- `/api/subscriptions/status` returns explicit lifetime metadata for granted users.
- Premium-gated endpoints honor lifetime overrides without app changes.
- A bootstrap admin can establish subject-based admin authority without knowing a Cognito subject ID before registration.
- A protected admin API can grant and revoke lifetime premium for a user ID.
- A minimal internal admin page can perform lookup plus grant/revoke actions without becoming a general admin console.
- Reviewer or demo accounts can be provisioned through a narrow backend path and granted lifetime premium through the same override mechanism.
- The seed path can create the same entitlement override safely and idempotently.
- Tests cover the merged status logic, protected admin flow, and seed behavior.
- Documentation explains the mechanism without relying on hardcoded emails or unsafe manual steps.
