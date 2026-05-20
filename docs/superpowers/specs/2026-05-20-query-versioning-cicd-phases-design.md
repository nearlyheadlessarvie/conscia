# Query-String API Versioning And 3-Phase CI/CD Setup Design

## Goal

Move Conscia from path-based API versioning (`/api/v1/...`) to query-string versioning in one coordinated app+API release, while keeping backward compatibility only for the current app release and the immediately previous app release.

In the same effort, replace the current broad CI/CD setup notes with a phased setup guide that distinguishes:

1. The minimum needed to deploy infrastructure, API, and web now
2. The backend/runtime secrets and wiring needed for production auth, push, and store validation
3. The additional setup needed for full mobile release automation and store deployment

## Scope

This design covers:

- API versioning contract changes
- Flutter client request shaping for version and app metadata
- Backward compatibility policy for app releases
- Release coordination expectations
- Documentation updates, including CI/CD setup guidance

This design does not cover:

- Introducing a second live API contract such as `v=2`
- Supporting both `/api/v1/...` and `/api/...` indefinitely
- Full production secret-manager wiring for all runtime secrets
- App store upload automation details beyond the documentation and release-model implications

## Current State

The repository is currently standardized around path-based versioning:

- The ASP.NET API maps endpoints under `/api/v1/...`
- Flutter defaults `API_BASE_URL` to `.../api/v1/`
- Tests and docs assume `/api/v1/...`
- Release docs already mention componentized release tags and a basic release matrix

The Flutter app separately enforces store updates using store-version discovery. That mechanism is useful, but by itself it is not a compatibility strategy because:

- Store rollout timing is not perfectly synchronized with API deploy timing
- Some clients will still be one release behind during rollout
- The backend currently has no explicit policy for supported client app versions

## Requirements

### Functional

1. All versioned API routes must move from `/api/v1/...` to `/api/...`.
2. Version selection must come from a query parameter rather than the path.
3. The initial query-string contract must support only `v=1`.
4. The Flutter app must automatically send the API version on every API request.
5. The Flutter app must automatically send its app version/build metadata on every API request.
6. The backend must support only the current app release and the immediately previous app release.
7. Unsupported app releases must receive a structured upgrade-required response.
8. Health endpoints remain unversioned.
9. Docs and setup guides must reflect the new request contract and release policy.

### Non-Functional

1. The versioning mechanism should be simple to reason about for a small team.
2. The rollout should avoid maintaining both path-based and query-based public contracts long-term.
3. The compatibility policy should be explicit and centrally configurable.
4. The design should leave a clean path for a future `v=2`.

## Recommended Approach

Use query-string API versioning with a single version parameter, plus explicit app-version headers.

### Request Contract

Versioned API endpoints move from:

- `/api/v1/auth/login`
- `/api/v1/users/me`
- `/api/v1/transactions`

to:

- `/api/auth/login?v=1`
- `/api/users/me?v=1`
- `/api/transactions?v=1`

The Flutter client should not manually append `?v=1` in every service. Instead, the shared Dio client should inject the query parameter automatically for relative API calls.

### App Metadata

The Flutter client should send an app-version header on API requests, for example:

- `X-Conscia-App-Version: 1.2.0+45`

This value should come from the installed app package metadata rather than a hand-maintained constant.

### Compatibility Policy

The backend should support:

- the current app release
- the immediately previous app release

Anything older should receive a structured error that tells the client an update is required.

This policy is intentionally based on app release compatibility, not permanent support for every historical client.

## Why This Approach

### Advantages

- Keeps the public route shape stable at `/api/...`
- Makes future version bumps explicit without duplicating route trees unnecessarily
- Avoids scattering version logic across Flutter services
- Gives the backend a real compatibility mechanism instead of relying only on app-store update prompts
- Matches the team’s preference for one coordinated cutover instead of a long migration tail

### Trade-Offs

- This is a broad repo-wide change because tests, docs, and examples all reference `/api/v1`
- Query-string versioning is slightly less conventional than path versioning in public APIs
- The first release still needs some backend infrastructure to validate and compare client app versions

## Alternatives Considered

### 1. Keep Path Versioning

Rejected because the explicit direction is to move to query-string versioning.

### 2. Query Versioning With Rich Date-Based Versions

Example: `?api-version=2026-05`

Rejected for now because it is more verbose than needed and does not buy much at the current scale.

### 3. Header-Only API Versioning

Example: `X-API-Version: 1`

Rejected because the request requirement is specifically to use query-string versioning.

### 4. Dual-Route Transition (`/api/v1/...` and `/api/...`) For Multiple Releases

Rejected because the agreed direction is one coordinated cutover, not a long deprecation window.

## Architecture

## API Surface

The API should move to a common unversioned route base:

- `/api/auth/...`
- `/api/users/...`
- `/api/transactions/...`
- `/api/budgets/...`
- `/api/subscriptions/...`
- `/api/ai/...`
- `/api/receipts/...`
- `/api/alerts/...`
- `/api/push/...`
- `/api/insights/...`
- `/api/family-space/...`
- `/api/recurring/...`
- `/api/categories/...`
- `/api/conscience-journey/...`
- `/api/suggestions/...`
- `/api/exchange-rates/...`

Health endpoints remain:

- `/health`
- `/health/live`
- `/health/ready`

The API root endpoint becomes:

- `/api?v=1`

## Version Resolution

Introduce a small API-version resolution layer that:

1. Reads `v` from the query string
2. Applies only to versioned `/api/...` endpoints
3. Rejects missing versions
4. Rejects unknown versions
5. Stores the resolved version in request context for downstream code

For this release, the only accepted version is `1`.

This resolution can live in middleware or a focused helper, but it should be centralized so endpoint code does not duplicate version parsing.

## App Release Compatibility Resolution

Introduce a separate client-release compatibility layer that:

1. Reads `X-Conscia-App-Version`
2. Parses semantic version plus build number
3. Compares it against configured support bounds
4. Allows:
   - current supported release
   - previous supported release
5. Rejects anything older with an upgrade-required response

This check should be centralized rather than spread across individual endpoints.

## Configuration Model

The backend should have a small configuration section for app compatibility, for example:

- `CurrentSupportedAppVersion`
- `PreviousSupportedAppVersion`
- optional `MinimumSupportedBuild`

The exact names can be finalized during implementation, but the configuration must clearly express the two-release support window.

The release process should update these values when a new coordinated app+API release is cut.

## Error Contract

Unsupported API-version errors should return a clear bad-request response, for example:

- code indicating unsupported or missing API version
- message indicating `v=1` is required

Unsupported app-release errors should return a structured response suitable for the Flutter blocker UI, for example:

- code such as `upgrade_required`
- message suitable for display
- current supported app version
- optional store/update URL if appropriate later

This keeps upgrade policy explicit rather than surfacing as random contract failures deeper in the request lifecycle.

## Flutter Client Design

## Base URL

Change Flutter `API_BASE_URL` from:

- `https://api.getconscia.com/api/v1/`

to:

- `https://api.getconscia.com/api/`

Relative service paths remain path-only, such as:

- `auth/login`
- `users/me`
- `transactions`

## Automatic Query Version Injection

The shared Dio client should automatically append `v=1` to versioned API requests.

That logic should:

- apply only to app API calls
- preserve existing query parameters
- avoid touching absolute health URLs

This keeps version policy in one place and prevents accidental drift between services.

## Automatic App-Version Header Injection

The shared Dio client should also attach:

- `X-Conscia-App-Version`

The source of truth should be package metadata already available on-device. This avoids hardcoding app versions in multiple places.

## App Availability Behavior

The current store-update blocker remains useful and should stay in place.

However, after this change it becomes one layer in a two-layer system:

1. Client-side store update awareness
2. Server-side compatibility enforcement

If the backend rejects an unsupported app release, the app should map that response into the same general “update required” experience rather than treating it as a generic API outage.

## Release Strategy

## Coordinated Cutover

This should ship as one coordinated app+API release:

1. Deploy API support for query-string versioning and app-version compatibility checks
2. Release the Flutter app configured for `/api/...` plus automatic `v=1`
3. Update release docs and release matrix in the same release train

There is no long-lived support promise for `/api/v1/...`.

## Release Matrix Policy

The release matrix should explicitly record:

- API contract version in use
- current supported app version
- previous supported app version
- whether the release contains a compatibility boundary

That makes future cutovers operationally clear.

## CI/CD Documentation Restructure

Replace the current flat setup guidance with three phases.

### Phase 1: Deploy Core Infrastructure, API, And Web

This phase should cover only what is needed to get these workflows functioning:

- `release-infra.yml`
- `release-api.yml`
- `release-web.yml`

It should include:

- AWS OIDC deploy role
- AWS region
- domain names
- Route 53 hosted zone ID
- CDK bootstrap expectations

It should not imply that app-store automation or production social auth is already wired.

### Phase 2: Production Runtime Secrets And Backend Wiring

This phase should cover what is needed for production-grade backend behavior, including:

- social auth runtime secrets
- app JWT signing configuration
- push-delivery backend credentials
- store-validation backend credentials
- expected eventual source of truth such as AWS Secrets Manager or SSM

It should clearly distinguish:

- values that exist today in docs only
- values already consumed by code
- values not yet fully wired into deployed infrastructure

### Phase 3: Mobile Release Automation And Store Delivery

This phase should cover what is needed for a real mobile release pipeline:

- Firebase client config injection
- Android release signing
- Play deployment credentials
- iOS signing assets
- App Store Connect credentials
- workflow changes needed beyond today’s artifact-only app build

This phase should explicitly note that the current app workflow builds artifacts but does not yet perform full signed store release automation.

## Testing Strategy

## API Tests

Add tests for:

- `/api/...` request succeeds with `v=1`
- request fails when `v` is missing
- request fails when `v` is unsupported
- request succeeds when app version equals current supported release
- request succeeds when app version equals previous supported release
- request fails with upgrade-required response when app version is older than previous supported release

## Flutter Tests

Add tests for:

- Dio appends `v=1` automatically
- Dio preserves existing query parameters while adding `v=1`
- Dio adds `X-Conscia-App-Version`
- absolute health requests stay unversioned
- unsupported app-version response maps to update-required UI instead of generic outage UI

## Documentation Updates

Update:

- README API examples
- Flutter run/build examples
- release setup docs
- release matrix
- any architecture docs that describe `/api/v1`

Examples should prefer the conceptual style:

- base URL: `https://api.getconscia.com/api/`
- version: query parameter `v=1`

## Rollout Notes

Because this is a coordinated cutover, release order matters:

1. Merge and deploy backend support first
2. Release the app immediately after
3. Update the compatibility matrix to support the new current release and the previous release

Operationally, this means the backend must be prepared to support both:

- the newly released app
- the app release immediately before it

but not older versions.

## Risks

### Risk: Repo-Wide Breakage During Migration

Many tests and docs are path-coupled to `/api/v1`.

Mitigation:

- centralize mechanical replacements
- keep endpoint path definitions consistent
- add focused tests around the new version-resolution layer

### Risk: Inconsistent Handling Between Health And API Requests

The app currently treats health differently from normal API calls.

Mitigation:

- explicitly scope version injection to normal API requests
- leave health endpoints unversioned

### Risk: Store Update Timing Mismatch

Some clients will still be on the previous app release while the new app rolls out.

Mitigation:

- support current + previous app release server-side
- do not rely solely on store update prompts

### Risk: Over-Engineering Future Version Support

Adding too much abstraction now could slow delivery.

Mitigation:

- implement only `v=1`
- build a small centralized resolver
- defer `v=2` route branching until it is actually needed

## Final Recommendation

Implement a coordinated cutover to:

- `/api/...` routes
- query-string API versioning using `?v=1`
- automatic Flutter injection of `v=1`
- automatic Flutter app-version header injection
- backend enforcement of current + previous app release support

At the same time, rewrite the CI/CD setup guide into three phases so the deployment prerequisites, runtime production wiring, and mobile-store automation work are clearly separated.

This gives Conscia a lightweight but explicit compatibility model that fits a mobile app with staged rollouts, without forcing the team to maintain legacy path-versioned routes indefinitely.
