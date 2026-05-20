# Release Automation And Onboarding Redirect Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the routable onboarding landing page and add per-component release PR automation with automatic app compatibility window updates.

**Architecture:** Keep app routing changes minimal by redirecting `/onboarding` to sign-in while preserving nested auth routes. Add `release-please` in manifest mode for component releases, plus a small repository script that synchronizes API compatibility metadata and the release matrix whenever an app release PR is prepared.

**Tech Stack:** Flutter, GoRouter, Dart tests, GitHub Actions, release-please, PowerShell/Node-friendly repo scripting, .NET config files.

---

### Task 1: Redirect `/onboarding` to sign-in

**Files:**
- Modify: `app/lib/core/routing/app_router.dart`
- Test: `app/test/core/routing/app_router_test.dart`

- [ ] Add a failing router test that navigating to `/onboarding` renders the sign-in experience, not the onboarding carousel.
- [ ] Run the focused Flutter router test and verify it fails for the expected reason.
- [ ] Change the `/onboarding` route to redirect to `AppRoutes.signIn` instead of building `OnboardingScreen`.
- [ ] Run the focused Flutter router test and confirm it passes.
- [ ] Run the full router test file to confirm no routing regressions.

### Task 2: Add release-please manifest/config and workflow

**Files:**
- Create: `.github/workflows/release-please.yml`
- Create: `.release-please-config.json`
- Create: `.release-please-manifest.json`
- Modify: `.github/workflows/release-api.yml`
- Modify: `.github/workflows/release-app.yml`
- Modify: `.github/workflows/release-infra.yml`
- Modify: `.github/workflows/release-web.yml`

- [ ] Add a failing validation step by checking that the repo currently has no release-please workflow/config.
- [ ] Create `release-please` manifest/config for `app`, `api`, `infra`, and `web` with component-specific tags and release PR generation.
- [ ] Add a workflow that runs on pushes to `main` and updates release PRs using the GitHub token.
- [ ] Update existing release workflows only where needed so they continue to consume `app/v*`, `api/v*`, `infra/v*`, and `web/v*` tags cleanly.
- [ ] Verify the workflow/config files are internally consistent by inspecting paths, component names, and tag formats.

### Task 3: Automate app compatibility window updates during app releases

**Files:**
- Create: `scripts/update-app-release-metadata.ps1`
- Modify: `src/Conscia.Api/appsettings.json`
- Modify: `src/Conscia.Api/appsettings.Development.json`
- Modify: `release-matrix.md`

- [ ] Write a failing script-level verification flow using fixture inputs or dry-run output expectations for version shifting.
- [ ] Implement a script that reads `app/pubspec.yaml`, shifts `CurrentSupportedAppVersion` to `PreviousSupportedAppVersion`, writes the new app version as current, and updates `release-matrix.md`.
- [ ] Make the script idempotent for repeated release PR refreshes.
- [ ] Verify the script updates both API config files and the release matrix correctly from the current repo state.

### Task 4: Wire compatibility updater into app release PR preparation

**Files:**
- Modify: `.github/workflows/release-please.yml`
- Modify: `.release-please-config.json`
- Modify: `.release-please-manifest.json`
- Modify: `scripts/update-app-release-metadata.ps1`

- [ ] Determine the safest trigger point for the compatibility updater in the release PR flow.
- [ ] Wire the updater so app release preparation applies metadata changes before or alongside the release PR contents.
- [ ] Verify the workflow logic is reviewable and does not mutate unrelated components when only app changes release.

### Task 5: Document the release policy

**Files:**
- Modify: `release-matrix.md`
- Modify: `.github/CICD_SETUP.md`
- Modify: `README.md`

- [ ] Document that releases are prepared as PRs, not immediate deploys on every merge.
- [ ] Document Conventional Commit expectations for semver automation.
- [ ] Document how app build versions map to API contract `v=1` and the server support window.
- [ ] Verify docs are consistent with the actual workflow and compatibility config.

### Task 6: Verify end to end

**Files:**
- Test: `app/test/core/routing/app_router_test.dart`
- Test: `scripts/update-app-release-metadata.ps1`

- [ ] Run focused Flutter routing tests.
- [ ] Run the compatibility updater locally in a safe verification mode and inspect the resulting file changes.
- [ ] Run any additional focused tests affected by routing or auth entry.
- [ ] Summarize residual limitations, especially that release-please behavior is verified by config/script inspection rather than a real GitHub release in this local session.
