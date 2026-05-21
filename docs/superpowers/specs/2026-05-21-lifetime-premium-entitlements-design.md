# Lifetime Premium Entitlements Design

## Goal

Add backend-owned lifetime premium entitlements for specific users, keyed by user ID, so Conscia can comp premium access without app-side hardcoded emails or store receipts.

## Scope

This design covers:

- a durable backend entitlement override record for lifetime premium grants
- effective subscription status resolution that merges normal subscription state with overrides
- a protected admin API to grant and revoke lifetime premium by user ID
- a seed path that writes the same backend-owned override data for local or controlled environments
- tests for the service layer, API behavior, and seed behavior
- release-safe documentation for operators and developers

This design does not cover:

- a general-purpose RBAC or full admin console
- app-side admin UI
- additional entitlement types beyond lifetime premium
- changing store verification behavior for iOS or Android purchases

## Requirements

- The override source of truth must be a backend record keyed by user ID.
- Premium checks must honor lifetime overrides everywhere `ISubscriptionService.IsPremiumAsync` is used.
- `/api/subscriptions/status` must return effective status, not only raw store subscription data.
- Lifetime premium must remain distinct from paid subscriptions in the status payload.
- Admin grant and revoke behavior must use the same backend code path as seeded grants.
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

### Seeder Tests

Add or extend tests so the seeder path:

- writes the lifetime override for the intended user ID
- is safe to rerun without duplicates
- does not depend on app-side email matching

## Documentation

Add short release-safe documentation covering:

- what lifetime premium entitlement overrides are
- that they are backend-owned and keyed by user ID
- how to grant and revoke them through the protected admin path
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
- The implementation should remain small and specific to lifetime premium. Do not generalize into a broad entitlement platform unless the code naturally needs one small shared abstraction.

## Acceptance Criteria

- A backend record keyed by user ID can grant lifetime premium access.
- `ISubscriptionService.IsPremiumAsync` returns `true` for granted users.
- `/api/subscriptions/status` returns explicit lifetime metadata for granted users.
- Premium-gated endpoints honor lifetime overrides without app changes.
- A protected admin API can grant and revoke lifetime premium for a user ID.
- The seed path can create the same entitlement override safely and idempotently.
- Tests cover the merged status logic, protected admin flow, and seed behavior.
- Documentation explains the mechanism without relying on hardcoded emails or unsafe manual steps.
