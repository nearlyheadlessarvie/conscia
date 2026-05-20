# Release App Store Automation Design

## Goal

Turn `release-app.yml` from an unsigned artifact build into a real mobile release pipeline that:

- builds signed Android and iOS release artifacts
- uploads Android builds to Google Play `internal`
- uploads iOS builds to TestFlight
- keeps GitHub Actions artifacts for debugging and rollback support

## Scope

This pass covers app release automation only. It does not change API, infra, or web release flows.

The workflow continues to trigger from `app/v*` tags so it fits the existing component-based release model and the new release PR automation.

## Current State

`release-app.yml` currently:

- runs Flutter tests
- builds an Android App Bundle without release signing configuration
- builds iOS with `--no-codesign`
- uploads artifacts to GitHub Actions only

That means the current workflow is useful for smoke-checking mobile releases, but not for store-ready distribution.

## Target State

The app release workflow should have two real release jobs:

### Android

- restore Flutter dependencies
- generate code
- materialize production config files from GitHub secrets
- materialize Android signing files from GitHub secrets
- build a signed `.aab`
- upload the `.aab` as a workflow artifact
- upload the `.aab` to the Google Play `internal` track

### iOS

- restore Flutter dependencies
- generate code
- materialize production config files from GitHub secrets
- import signing certificate and provisioning profile
- install App Store Connect API key
- build an archive and export an `.ipa`
- upload the `.ipa` as a workflow artifact
- upload the `.ipa` to TestFlight

## Inputs

### Build-time app config

Use existing repo variables/secrets:

- `vars.API_BASE_URL`
- `vars.MOCK_AUTH`
- `vars.PUSH_NOTIFICATIONS_ENABLED`
- `secrets.GOOGLE_SERVER_CLIENT_ID`

These must be passed into Flutter release builds via `--dart-define`.

### Android config

- `secrets.ANDROID_GOOGLE_SERVICES_JSON_BASE64`
- optional `secrets.FIREBASE_OPTIONS_DART_BASE64`
- `secrets.ANDROID_KEYSTORE_BASE64`
- `secrets.ANDROID_KEYSTORE_PASSWORD`
- `secrets.ANDROID_KEY_ALIAS`
- `secrets.ANDROID_KEY_PASSWORD`
- `secrets.GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON`

### iOS config

- `secrets.IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64`
- optional `secrets.FIREBASE_OPTIONS_DART_BASE64`
- `secrets.APP_STORE_CONNECT_API_KEY_ID`
- `secrets.APP_STORE_CONNECT_ISSUER_ID`
- `secrets.APP_STORE_CONNECT_API_PRIVATE_KEY`
- `secrets.IOS_CERTIFICATE_P12_BASE64`
- `secrets.IOS_CERTIFICATE_PASSWORD`
- `secrets.IOS_PROVISIONING_PROFILE_BASE64`
- `vars.IOS_BUNDLE_ID`

## Repository Changes

### Workflow

Update `.github/workflows/release-app.yml` to:

- fail fast when required secrets are missing
- decode config/signing files only inside the job workspace
- build with production `--dart-define`s
- upload store-ready artifacts
- publish Android to Play internal
- publish iOS to TestFlight

### Android signing

Update `app/android/app/build.gradle.kts` so the release build no longer uses debug signing. Instead:

- read signing properties from CI-generated `key.properties`
- use release signing only when those values exist
- keep local developer ergonomics intact for non-release flows

### Optional helper scripts

If the workflow gets unwieldy, add small repo scripts for:

- decoding Firebase files
- writing Android signing properties
- importing iOS signing assets

The goal is readability and repeatability, not adding complexity for its own sake.

## Distribution Strategy

First-pass automation should be intentionally conservative:

- Android uploads to Play `internal`
- iOS uploads to TestFlight
- no automatic production rollout
- no automatic App Store review submission
- no automatic Play track promotion

This gives a real end-to-end release path with much lower operational risk than direct production publishing.

## Failure Model

The workflow should fail early and clearly when:

- a required secret is missing
- a signing asset cannot be decoded
- Android signing config is incomplete
- iOS signing import fails
- Play upload fails
- TestFlight upload fails

Store upload failure should still preserve the built artifact in GitHub Actions when possible so the run remains debuggable.

## Validation

Local validation before merge:

- `flutter analyze`
- `flutter test`
- inspect Android Gradle release signing configuration
- inspect workflow YAML for all referenced secrets/variables

Post-merge validation:

- trigger first real `app/v*` release from the draft PR/tag flow
- confirm signed `.aab` appears in Play internal
- confirm `.ipa` appears in TestFlight
- confirm GitHub workflow artifacts are still uploaded

## Non-Goals

This pass does not include:

- automatic Play production rollout
- automatic App Store production submission
- store metadata/screenshots management
- phased rollout orchestration
- notarization-like extra release governance beyond store upload

## Recommendation

Implement this as one focused pass now, because it makes Phase 3 of `CICD_SETUP.md` materially real instead of merely documented. Keep the rollout channels conservative so we validate credentials, signing, and store connectivity before any production release automation is considered.
