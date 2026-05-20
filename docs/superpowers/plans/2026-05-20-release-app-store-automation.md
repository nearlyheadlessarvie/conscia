# Release App Store Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `release-app.yml` build signed Android and iOS releases, upload Android to Play internal, upload iOS to TestFlight, and keep workflow artifacts for debugging.

**Architecture:** Keep the current tag-driven app release flow, but expand it into two real distribution jobs: Android signing and Play upload on Ubuntu, iOS signing and TestFlight upload on macOS. Support this with one Android build configuration change and a workflow that materializes secrets/config files only at runtime.

**Tech Stack:** GitHub Actions, Flutter, Android Gradle Kotlin DSL, Google Play Developer API, App Store Connect API, iOS signing on macOS.

---

### Task 1: Make Android release signing configurable for CI

**Files:**
- Modify: `app/android/app/build.gradle.kts`

- [ ] **Step 1: Write the failing configuration expectation**

Document the target release behavior inline by asserting the release build no longer uses debug signing and instead reads CI-provided signing properties.

Expected target structure:

```kotlin
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

- [ ] **Step 2: Inspect the current release signing block**

Read `app/android/app/build.gradle.kts` and confirm it currently does:

```kotlin
release {
    signingConfig = signingConfigs.getByName("debug")
}
```

Expected: release signing is currently wrong for CI store releases.

- [ ] **Step 3: Implement CI-aware release signing**

Update `app/android/app/build.gradle.kts` to:

- load `key.properties` when present
- create a `release` signing config from the file
- use that config only for release builds
- keep non-release developer flows intact

Target code shape:

```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

and

```kotlin
signingConfigs {
    create("release") {
        val storeFilePath = keystoreProperties["storeFile"] as String?
        if (!storeFilePath.isNullOrBlank()) {
            storeFile = file(storeFilePath)
            storePassword = keystoreProperties["storePassword"] as String?
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
        }
    }
}
```

- [ ] **Step 4: Verify the file reflects CI signing**

Run:

```bash
Get-Content app/android/app/build.gradle.kts
```

Expected: debug signing is no longer used for the release build.

- [ ] **Step 5: Commit**

```bash
git add app/android/app/build.gradle.kts
git commit -m "feat(app): add CI release signing config"
```

### Task 2: Make the Android release workflow produce a signed AAB and upload to Play internal

**Files:**
- Modify: `.github/workflows/release-app.yml`

- [ ] **Step 1: Write the failing workflow expectation**

Record the missing requirements by comparing the current Android job against this target checklist:

- decodes `google-services.json`
- writes `key.properties`
- writes keystore from base64 secret
- passes production `--dart-define`s
- uploads to Play internal

Expected: current workflow is missing all of these.

- [ ] **Step 2: Add fail-fast secret validation for Android**

Add a workflow step that checks these are present:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON`
- `ANDROID_GOOGLE_SERVICES_JSON_BASE64`
- `GOOGLE_SERVER_CLIENT_ID`

Expected command shape:

```bash
test -n "${ANDROID_KEYSTORE_BASE64}" || (echo "Missing ANDROID_KEYSTORE_BASE64" && exit 1)
```

- [ ] **Step 3: Materialize Android config and signing assets**

Add workflow steps to:

- decode `ANDROID_GOOGLE_SERVICES_JSON_BASE64` to `app/android/app/google-services.json`
- decode `ANDROID_KEYSTORE_BASE64` to `app/android/conscia-release.jks`
- write `app/android/key.properties`

Target file content for `key.properties`:

```text
storeFile=conscia-release.jks
storePassword=${ANDROID_KEYSTORE_PASSWORD}
keyAlias=${ANDROID_KEY_ALIAS}
keyPassword=${ANDROID_KEY_PASSWORD}
```

- [ ] **Step 4: Build the signed Android App Bundle**

Replace the current Android build command with a release build that passes:

- `--dart-define=API_BASE_URL=${{ vars.API_BASE_URL }}`
- `--dart-define=MOCK_AUTH=${{ vars.MOCK_AUTH }}`
- `--dart-define=PUSH_NOTIFICATIONS_ENABLED=${{ vars.PUSH_NOTIFICATIONS_ENABLED }}`
- `--dart-define=GOOGLE_SERVER_CLIENT_ID=${{ secrets.GOOGLE_SERVER_CLIENT_ID }}`

Expected command shape:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=... \
  --dart-define=MOCK_AUTH=... \
  --dart-define=PUSH_NOTIFICATIONS_ENABLED=... \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=...
```

- [ ] **Step 5: Upload to Play internal**

Add a Google Play upload action step using `GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON` and the built `.aab`.

Expected inputs:

- package name from `vars.GOOGLE_PLAY_PACKAGE_NAME`
- release file `app/build/app/outputs/bundle/release/app-release.aab`
- track `internal`

- [ ] **Step 6: Verify workflow structure**

Run:

```bash
Get-Content .github/workflows/release-app.yml
```

Expected: Android job now includes secret checks, file materialization, signed build, artifact upload, and Play internal upload.

- [ ] **Step 7: Commit**

```bash
git add .github/workflows/release-app.yml
git commit -m "feat(app): upload signed Android releases to Play internal"
```

### Task 3: Make the iOS release workflow produce an IPA and upload to TestFlight

**Files:**
- Modify: `.github/workflows/release-app.yml`

- [ ] **Step 1: Write the failing workflow expectation**

Record the missing requirements by comparing the current iOS job against this target checklist:

- decodes `GoogleService-Info.plist`
- imports distribution certificate and provisioning profile
- installs App Store Connect API key
- builds signed archive and exports IPA
- uploads to TestFlight

Expected: current workflow only builds with `--no-codesign`.

- [ ] **Step 2: Add fail-fast secret validation for iOS**

Add checks for:

- `IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_PRIVATE_KEY`
- `IOS_CERTIFICATE_P12_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISIONING_PROFILE_BASE64`
- `GOOGLE_SERVER_CLIENT_ID`

- [ ] **Step 3: Materialize iOS config and signing assets**

Add steps to:

- decode `IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64` to `app/ios/Runner/GoogleService-Info.plist`
- create a temporary keychain
- import the P12 certificate
- install the provisioning profile
- write the App Store Connect API key `.p8` file

- [ ] **Step 4: Build and export the IPA**

Replace `flutter build ios --release --no-codesign` with a signed archive/export flow, using Flutter plus `xcodebuild` export if needed.

Target behavior:

- Flutter build passes the same production `--dart-define`s as Android
- archive is created
- IPA is exported to a predictable path

- [ ] **Step 5: Upload to TestFlight**

Add a TestFlight upload step using the App Store Connect API key inputs and the exported IPA.

Expected behavior:

- uploads to TestFlight only
- does not auto-submit for App Store review

- [ ] **Step 6: Verify workflow structure**

Run:

```bash
Get-Content .github/workflows/release-app.yml
```

Expected: iOS job now includes secret checks, config decoding, signing import, IPA export, artifact upload, and TestFlight upload.

- [ ] **Step 7: Commit**

```bash
git add .github/workflows/release-app.yml
git commit -m "feat(app): upload signed iOS releases to TestFlight"
```

### Task 4: Make optional Firebase/runtime files CI-friendly

**Files:**
- Modify: `.github/workflows/release-app.yml`

- [ ] **Step 1: Write the failing workflow expectation**

Document the optional behavior:

- if `FIREBASE_OPTIONS_DART_BASE64` is present, write `app/lib/firebase_options.dart`
- otherwise leave the committed file alone

Expected: current workflow has no such support.

- [ ] **Step 2: Add optional decode step**

Add a guarded workflow step:

```bash
if [ -n "${FIREBASE_OPTIONS_DART_BASE64}" ]; then
  echo "$FIREBASE_OPTIONS_DART_BASE64" | base64 --decode > app/lib/firebase_options.dart
fi
```

- [ ] **Step 3: Verify the guard is non-destructive**

Run:

```bash
Get-Content .github/workflows/release-app.yml
```

Expected: the step is conditional and does not require the secret.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/release-app.yml
git commit -m "chore(app): support optional firebase options override"
```

### Task 5: Update docs so Phase 3 is operational, not aspirational

**Files:**
- Modify: `.github/CICD_SETUP.md`
- Modify: `.github/GITHUB_SECRETS.template.md`
- Modify: `README.md`

- [ ] **Step 1: Document the new app release behavior**

Update docs to say `release-app.yml` now:

- builds signed Android AABs
- uploads to Play internal
- builds signed iOS IPAs
- uploads to TestFlight

- [ ] **Step 2: Document required secrets precisely**

Ensure the exact secret/variable names in docs match the workflow inputs:

- Android signing
- iOS signing
- store API credentials
- build-time `--dart-define` values

- [ ] **Step 3: Document first-run rollout expectations**

Add notes that:

- uploads go to Play internal and TestFlight only
- production release/promotion is still manual
- artifacts are preserved in GitHub Actions

- [ ] **Step 4: Verify docs match workflow names**

Run:

```bash
rg -n "ANDROID_KEYSTORE_BASE64|GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON|APP_STORE_CONNECT_API_KEY_ID|IOS_CERTIFICATE_P12_BASE64|TestFlight|internal" .github README.md
```

Expected: docs and workflow use the same names and rollout targets.

- [ ] **Step 5: Commit**

```bash
git add .github/CICD_SETUP.md .github/GITHUB_SECRETS.template.md README.md
git commit -m "docs(app): document automated internal and TestFlight releases"
```

### Task 6: Verify the end-to-end workflow definition

**Files:**
- Modify: `.github/workflows/release-app.yml`
- Modify: `app/android/app/build.gradle.kts`

- [ ] **Step 1: Run Flutter static verification**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 2: Run Flutter tests**

Run:

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 3: Run YAML/input sanity review**

Run:

```bash
Get-Content .github/workflows/release-app.yml
```

and verify:

- every referenced secret exists in docs
- Android upload target is `internal`
- iOS upload target is TestFlight
- artifacts are still uploaded even when store uploads are configured

- [ ] **Step 4: Summarize residual risk**

Document that the remaining unverified piece is the first real GitHub tag run with live store credentials, because that cannot be fully simulated locally.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/release-app.yml app/android/app/build.gradle.kts
git commit -m "chore(app): finalize store release workflow verification"
```
