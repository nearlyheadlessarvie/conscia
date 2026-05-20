# Release Automation And Onboarding Redirect Design

## Goal

Remove the stray onboarding landing surface from normal app entry and add reviewable, per-component release automation that:

- creates release PRs from Conventional Commit history
- tags component releases only after PR merge
- keeps app and API compatibility metadata in sync

## Scope

This design covers three linked changes:

1. Make `/onboarding` a redirect-only route so first-launch users cannot land on the carousel again through stale or explicit navigation.
2. Add `release-please`-based release PR automation for `app`, `api`, `infra`, and `web`.
3. Automatically update the API app compatibility window when preparing an app release.

## Onboarding Routing

The onboarding carousel screen still exists and is still mounted at `/onboarding`, even though unauthenticated first-launch routing now redirects to `/onboarding/sign-in`. That means any stale route state or explicit navigation to `/onboarding` can still show the old landing experience.

The fix is to make `/onboarding` redirect to `/onboarding/sign-in` instead of rendering `OnboardingScreen`. This preserves the nested auth routes under `/onboarding/*` while removing the standalone landing page from the app flow. The carousel widget can remain in the codebase only if tests or future marketing previews still need it; it should no longer be routable as the default onboarding entry point.

## Release Automation

Use `release-please` in manifest mode with one package per deployable component:

- `app`
- `api`
- `infra`
- `web`

Each component gets its own release PR and tag namespace:

- `app/vX.Y.Z`
- `api/vX.Y.Z`
- `infra/vX.Y.Z`
- `web/vX.Y.Z`

Release PRs are driven by Conventional Commit history. The release PR is reviewable and contains version bumps plus compatibility metadata changes. Merging the release PR creates the component tag, which continues to drive the existing tag-based deployment workflows.

## Version Sources

Version sources remain local to each component:

- App: `app/pubspec.yaml`
- API: `src/Conscia.Api/Conscia.Api.csproj`
- Infra: `infra/src/Conscia.Infra/Conscia.Infra.csproj`
- Web: add `web/package.json` version if needed for release tracking, even if deploy is static

## App And API Compatibility

Three version concepts stay separate:

1. API contract version: query string `v=1`
2. App build version: `X-Conscia-App-Version`, for example `1.2.3+45`
3. Server support window: current and previous supported app releases

The support window stays in API config:

- `src/Conscia.Api/appsettings.json`
- `src/Conscia.Api/appsettings.Development.json`

When an app release PR is created:

- the new app version becomes `CurrentSupportedAppVersion`
- the previous `CurrentSupportedAppVersion` becomes `PreviousSupportedAppVersion`
- `release-matrix.md` is updated to reflect the new app version and supported API contract family

This keeps the current-plus-previous support promise synchronized with app releases instead of relying on manual edits after the fact.

## Automation Shape

Add:

- a `release-please` workflow that opens/updates release PRs
- a repo-level manifest/config for component strategies and tag separators
- a small script that updates API compatibility files and `release-matrix.md` during app release preparation

The compatibility update script should be deterministic and idempotent so it can run safely on every release PR refresh.

## Testing

Add focused regression coverage for routing:

- `/onboarding` redirects to sign-in
- first-time unauthenticated app startup still lands on sign-in

For release automation, add script-level verification rather than trying to fully simulate GitHub releases locally:

- compatibility updater adjusts both appsettings files
- compatibility updater updates `release-matrix.md`
- version parser reads the app version from `pubspec.yaml`

## Risks And Constraints

- Release automation is only as good as commit discipline. Conventional Commits should be adopted for merge commits or PR titles.
- `release-please` can update version files automatically, but the app compatibility window is custom logic and needs a repo script.
- Existing tag-based release workflows stay intact, so this change layers automation on top of the current deployment model rather than replacing it.
