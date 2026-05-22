# Apple Subscription Notifications And Transaction Date Filters Design

## Goal

Add an Apple App Store Server Notifications V2 webhook that keeps Conscia subscription state current for iOS users, and add server-side transaction date filtering with practical finance-oriented presets in the app.

## Scope

This design covers:

- a public Apple notification endpoint for App Store Server Notifications V2
- JWS verification for the incoming `signedPayload`
- production and sandbox notification handling
- mapping Apple subscription lifecycle events into the existing `UserSubscription` model
- focused tests for endpoint behavior and subscription state transitions
- operator documentation for webhook URLs and App Store Connect setup
- server-side date filtering for transaction list APIs
- app-side date preset selection that resolves to concrete date ranges before calling the API

This design does not cover:

- Google Play Real-time Developer Notifications
- new infrastructure for Pub/Sub or other Google webhook delivery
- a large subscription-history or entitlement ledger redesign
- client-only transaction filtering
- non-transaction list screens unless they already depend on the same filtered API path

## Requirements

- Apple notifications must verify the signed JWS payload before the backend trusts the notification contents.
- The webhook must accept both production and sandbox notifications.
- Subscription state updates must cover renewal, cancellation, expiration, refund, billing retry, grace period, and revocation events.
- Existing client-driven receipt verification should remain available for initial linking of an Apple purchase token or transaction ID to a user.
- Unknown or currently unlinked Apple subscriptions must fail safely without creating guessed user records.
- Transaction date filtering must be performed on the server.
- Transaction filters must support `This week`, `Last week`, `This month`, `Last month`, `This year`, `Specific date`, and `Custom range`.
- The app should send concrete `from` and `to` values to the API rather than sending preset names.

## Recommended Approach

Keep the current purchase verification flow for initial subscription linking, and layer Apple server notifications on top as an asynchronous state synchronizer.

Why this approach:

- It fits the current backend model, where a `UserSubscription` is already linked to a user through an `OriginalTransactionId`.
- It avoids a larger redesign into a multi-record entitlement history system.
- It lets the backend stay current on renewal or billing status changes even when the app is not opened.
- It keeps transaction date filtering API-centric and durable while allowing the app to evolve preset UX independently.

Rejected alternatives:

- Replacing initial client verification entirely with server notifications would not work well because Apple notifications do not reliably give us a safe user mapping for first-time purchases unless the app has already linked the transaction.
- Adding API-level preset names such as `datePreset=thisMonth` would couple UI concepts to the backend contract more tightly than needed.
- Client-only filtering would not satisfy the requirement and would break pagination and large-history behavior.

## Apple Notification Model

### Endpoint Shape

Add a public unauthenticated Apple webhook endpoint dedicated to App Store Server Notifications V2.

Suggested route:

- `POST /api/subscriptions/apple/notifications`

Request body expectations:

- JSON payload with top-level `signedPayload`

Behavior:

- return `400` for missing or malformed payloads
- verify the JWS before reading notification contents
- decode notification type, subtype, and nested transaction or renewal details
- return a success response for valid notifications even when the notification is not actionable for a linked user

This endpoint should not require normal user authentication because Apple will call it directly.

### Verification Strategy

The backend should verify the JWS signature and certificate chain for Apple notifications rather than only decoding the payload.

Implementation expectations:

- parse the JWS header
- validate the embedded certificate chain against Apple trust requirements
- verify the JWS signature over the payload
- reject unverified payloads

The service should also read the notification environment from the verified payload so the backend can distinguish production and sandbox notifications without maintaining separate application behavior.

### Production And Sandbox

Apple will call different server URLs for Production and Sandbox configuration in App Store Connect.

We should document both URLs explicitly:

- Production Server URL
- Sandbox Server URL

The endpoint implementation itself can stay as one code path if both routes resolve to the same deployed service behavior. The important part is that operations documentation must tell the team which environment-specific App Store Connect field to configure.

## Subscription State Mapping

The current `UserSubscription` model is intentionally small:

- `Tier`
- `Platform`
- `ExpiresAt`
- `OriginalTransactionId`

This branch should keep that model and derive the effective state from Apple events using `Tier` and `ExpiresAt`.

### User Mapping Rule

The notification processor should look up the existing subscription using the Apple `originalTransactionId`.

Rules:

- if an existing `UserSubscription` with that `OriginalTransactionId` exists, update it
- if no linked subscription exists yet, log and acknowledge the notification without creating a guessed user record
- do not create placeholder subscriptions without a known user ID

This preserves the current trust boundary:

1. The app performs initial receipt verification.
2. The backend stores the `UserSubscription` tied to a user.
3. Apple notifications keep that stored record current afterward.

### Event Handling

Map the relevant Apple lifecycle changes into the current subscription record as follows.

Renewal and successful renewal-adjacent events:

- keep `Tier = Premium`
- update `ExpiresAt` to the latest known subscription expiry

Cancellation where access remains active until period end:

- keep `Tier = Premium`
- keep or update `ExpiresAt` to the current expiry

Expiration:

- set `Tier = Free`
- keep `ExpiresAt` at the final known expiry for auditability and current `IsActive` behavior

Refund or revocation:

- set `Tier = Free`
- if Apple provides a revocation or effective end date, store it in `ExpiresAt` when it clarifies the access cutoff

Billing retry:

- keep `Tier = Premium`
- keep current expiry
- do not immediately downgrade while Apple is retrying billing

Grace period:

- keep `Tier = Premium`
- update `ExpiresAt` if the notification provides a newer date

Because the current domain model does not include explicit cancellation reason or billing-state fields, this branch should not invent extra persisted state unless the implementation needs one minimal supporting field. If a richer lifecycle record becomes necessary later, it should be a follow-up change.

### Idempotency And Ordering

Apple notifications can be retried and can arrive close together.

The processor should therefore be safe for duplicate delivery:

- applying the same notification multiple times must not create duplicate subscriptions
- older events must not overwrite a newer `ExpiresAt` with an earlier value unless the event is a clear downgrade terminal state such as expiration or revocation

If the Apple payload provides a signed date or event timestamp, the processor should use that to avoid stale updates where practical.

## Application Structure

Keep responsibilities narrow:

- endpoint: receive request, validate shape, delegate
- verifier/parser service: verify JWS and decode Apple notification payloads
- notification processor service: map Apple notification types to subscription mutations
- subscription repository/service: perform record lookup and update persistence

This split keeps cryptographic verification concerns separate from business-state mapping and makes tests easier to write.

## Transaction Date Filtering

### API Contract

Extend `GET /api/transactions` with optional query parameters:

- `from`
- `to`

Rules:

- both values should be ISO 8601 timestamps
- if only one bound is supplied, the API should reject the request with a clear validation error
- if `from > to`, the API should reject the request
- date filtering should work for both personal and family transaction scopes

Existing parameters such as `page`, `pageSize`, `category`, and `scope` should continue to work.

### Service Behavior

Thread the optional date bounds through the transaction service instead of ignoring the repository’s existing date-range capability.

Personal transactions:

- use the repository query path with `from` and `to` bounds when supplied

Family transactions:

- apply the same date range to the family query path
- preserve current ordering and pagination behavior as closely as possible

The implementation should not broaden scope beyond the transaction list endpoint in this branch.

### App Presets

The app should present presets that reflect common personal finance review behavior:

- `This week`
- `Last week`
- `This month`
- `Last month`
- `This year`
- `Specific date`
- `Custom range`

Preset resolution should happen in the app:

- `Specific date` resolves to a one-day `from` and `to`
- range presets resolve to concrete local dates before calling the API
- `Custom range` allows the user to choose both bounds

Why this set:

- month-based views are the primary budgeting and salary-cycle lens
- weekly views help users who check in more frequently
- yearly view supports broader review without adding too many preset choices
- specific/custom cover search-like and ad hoc analysis behavior

### Timezone Semantics

The app and API must agree on what a “day” means for specific-date and preset boundaries.

Recommended rule:

- the app computes local calendar boundaries for the user
- the app sends concrete timestamp bounds in ISO format
- the backend filters using those exact timestamps

This keeps “This month” aligned with what the user sees locally and avoids the API guessing the user’s timezone.

## Testing

### Apple Notification Tests

Add unit or focused integration tests for:

- missing `signedPayload` returns `400`
- invalid or unverified JWS is rejected
- valid renewal notification updates `ExpiresAt` and keeps premium status
- valid cancellation notification preserves premium until expiry
- valid expiration notification downgrades to free
- valid refund or revocation notification downgrades to free
- billing retry notification does not prematurely downgrade the subscription
- grace period notification preserves premium state
- unlinked `originalTransactionId` is acknowledged without creating a guessed record
- duplicate notification handling is idempotent

### Transaction Filter Tests

Add API and service tests for:

- listing transactions with no date filters preserves existing behavior
- `from` and `to` filters reach the service and repository correctly
- invalid partial ranges are rejected
- reversed ranges are rejected
- family-scope filtered queries use the same requested bounds

App tests should cover:

- preset selection computes the expected request bounds
- `Specific date` resolves to a single-day range
- `Custom range` sends the chosen bounds

## Documentation

Update documentation with:

- the Production and Sandbox Apple Server Notification URLs
- required App Store Connect setup steps for Notifications V2
- notes on the initial receipt-linking dependency for user mapping
- the list of lifecycle events handled by the backend
- the fact that Google RTDN is intentionally deferred because Pub/Sub is not provisioned yet
- transaction filter behavior and supported presets if there is user-facing or API-facing documentation for transaction queries

App Store Connect notes should be explicit enough for an operator to configure:

- app selection
- notification version selection
- Production Server URL
- Sandbox Server URL
- any shared secrets or signing-related configuration only if actually required by the chosen implementation

## Operational Notes

- The Apple webhook must be reachable by Apple without end-user authentication.
- Logging should avoid leaking full signed payload contents unless necessary for local debugging.
- Unknown Apple notification types should be logged and safely acknowledged.
- The backend should remain robust if Apple sends notifications for transactions that are no longer active or were never linked in this environment.
- Google Play RTDN should be listed as a deferred follow-up, not an implemented capability.

## Acceptance Criteria

- Conscia exposes an Apple App Store Server Notifications V2 endpoint that verifies `signedPayload`.
- The endpoint handles both production and sandbox Apple notifications.
- Renewal, cancellation, expiration, refund, billing retry, grace period, and revocation events update `UserSubscription` appropriately.
- Existing client receipt verification remains available for first-time subscription linking.
- Unlinked Apple notifications do not create guessed user subscriptions.
- Transaction list APIs accept server-side `from` and `to` filtering.
- The app offers `This week`, `Last week`, `This month`, `Last month`, `This year`, `Specific date`, and `Custom range` presets and resolves them to concrete ranges before calling the API.
- Tests cover Apple notification verification and state transitions plus transaction filter API behavior.
- Documentation includes Production and Sandbox server URLs and App Store Connect setup notes.
