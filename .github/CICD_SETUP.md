# Conscia CI/CD Setup

This guide is organized into three phases so we only gather the values needed for the rollout we are actually doing.

- Phase 1 gets `infra`, `api`, and `web` deployable now.
- Phase 2 covers production auth, push, and store-validation backend wiring.
- Phase 3 covers real mobile release automation and store signing.

The API contract now uses a stable `/api/` base path with query-string versioning. The canonical client contract is:

```text
https://api.getconscia.com/api/... ?v=1
```

The API also accepts `X-Api-Version: 1` as a secondary input, but query-string versioning is the public default because it is easier to debug and less likely to be interfered with by proxies, CDNs, or future WAF rules.

---

## Prerequisites

- AWS account with an IAM user that has admin access for bootstrap only
- Route 53 hosted zone for `getconscia.com`
- GitHub CLI: `brew install gh && gh auth login`
- AWS CLI: `brew install awscli && aws configure`
- CDK CLI: `npm install -g aws-cdk`

---

## Phase 1: Minimum Needed To Deploy Now

This phase is enough to bootstrap CI/CD and release infrastructure, API, and web.

### Step 1: Bootstrap CDK And Deploy The CI/CD Stack

Run these locally with your admin IAM credentials:

```bash
# Get your AWS account ID
aws sts get-caller-identity --query Account --output text

# Bootstrap CDK
cd infra
cdk bootstrap aws://YOUR_ACCOUNT_ID/ap-southeast-1

# Deploy the stack that creates the GitHub Actions role
cdk deploy Conscia-CiCd

# Capture the role ARN for GitHub OIDC deploys
aws cloudformation describe-stacks \
  --stack-name Conscia-CiCd \
  --query "Stacks[0].Outputs[?ExportName=='ConsciaGitHubActionsRoleArn'].OutputValue" \
  --output text
```

### Required Phase 1 Secret

#### `AWS_DEPLOY_ROLE_ARN`

```bash
gh secret set AWS_DEPLOY_ROLE_ARN \
  --body "arn:aws:iam::YOUR_ACCOUNT_ID:role/conscia-github-actions" \
  --repo nearlyheadlessarvie/conscia
```

### Required Phase 1 Variables

#### `AWS_REGION`

```bash
gh variable set AWS_REGION --body "ap-southeast-1" --repo nearlyheadlessarvie/conscia
```

#### `CONSCIA_DOMAIN_NAME`

```bash
gh variable set CONSCIA_DOMAIN_NAME --body "getconscia.com" --repo nearlyheadlessarvie/conscia
```

#### `CONSCIA_WWW_DOMAIN_NAME`

```bash
gh variable set CONSCIA_WWW_DOMAIN_NAME --body "www.getconscia.com" --repo nearlyheadlessarvie/conscia
```

#### `CONSCIA_API_DOMAIN_NAME`

```bash
gh variable set CONSCIA_API_DOMAIN_NAME --body "api.getconscia.com" --repo nearlyheadlessarvie/conscia
```

#### `ROUTE53_HOSTED_ZONE_ID`

```bash
aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='getconscia.com.'].Id" \
  --output text
```

Use the hosted zone id without the `/hostedzone/` prefix:

```bash
gh variable set ROUTE53_HOSTED_ZONE_ID --body "Z04XXXXXXXXXXXXXXXXX" --repo nearlyheadlessarvie/conscia
```

### Phase 1 App Build-Time Variables

These are needed once the app workflow starts passing Flutter defines. They are still worth deciding now because they are part of the release contract.

#### `API_BASE_URL`

Use the stable `/api/` base path with a trailing slash:

```bash
gh variable set API_BASE_URL --body "https://api.getconscia.com/api/" --repo nearlyheadlessarvie/conscia
```

The app injects `?v=1` automatically on requests, so `API_BASE_URL` should not include the version.

#### `MOCK_AUTH`

```bash
gh variable set MOCK_AUTH --body "false" --repo nearlyheadlessarvie/conscia
```

#### `GOOGLE_SERVER_CLIENT_ID`

```bash
gh secret set GOOGLE_SERVER_CLIENT_ID --body "YOUR_CLIENT_ID.apps.googleusercontent.com" --repo nearlyheadlessarvie/conscia
```

#### `PUSH_NOTIFICATIONS_ENABLED`

```bash
gh variable set PUSH_NOTIFICATIONS_ENABLED --body "false" --repo nearlyheadlessarvie/conscia
```

### Phase 1 Verification

After setting the values above:

```bash
REPO="nearlyheadlessarvie/conscia"
echo "=== Secrets ===" && gh secret list --repo "$REPO"
echo "=== Variables ===" && gh variable list --repo "$REPO"
```

At this point you should be able to deploy:

- `release-infra.yml`
- `release-api.yml`
- `release-web.yml`

---

## Phase 2: Production API Runtime Wiring

This phase is for production auth, app compatibility policy, push delivery, family invite delivery, and store-validation credentials. These values should ultimately live in AWS Secrets Manager or SSM Parameter Store and be injected by CDK, not permanently sourced from GitHub Actions secrets.

The production API now validates these settings at startup. In `Production`, the app will refuse to boot if required auth, subscription, push, invite-email, or app-compatibility settings are missing.

### Auth And App Compatibility

#### `AUTH_APP_JWT_SIGNING_KEY`

```bash
openssl rand -base64 32
```

#### `AUTH_GOOGLE_CLIENT_ID`

Same value as `GOOGLE_SERVER_CLIENT_ID`.

#### `AUTH_APPLE_CLIENT_ID`

Usually the iOS bundle id, for example `com.conscia.app`.

### Store Validation

#### `APPLE_KEY_ID`

Only needed if server-side Apple validation is enabled.

#### `APPLE_ISSUER_ID`

From App Store Connect API access.

#### `APPLE_PRIVATE_KEY`

Private `.p8` contents for Apple server API access.

#### `GOOGLE_PLAY_PACKAGE_NAME`

Usually your Android package name, for example `com.conscia.app`.

How to confirm:

```bash
rg "applicationId" app/android
```

It should match the package registered in Google Play Console.

#### `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

Service account JSON for Play purchase validation.

### Push Delivery

#### `FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON`

Firebase Admin SDK JSON used by the real server-side FCM sender.

#### `FIREBASE_PROJECT_ID`

Firebase project id used when the push sender calls FCM. This should usually match the project used by the mobile Firebase config.

### Family Invite Email

#### `INVITE_EMAIL_DEEP_LINK_BASE_URI`

Default:

```bash
gh variable set INVITE_EMAIL_DEEP_LINK_BASE_URI \
  --body "https://getconscia.com/open/family-invite" \
  --repo nearlyheadlessarvie/conscia
```

The outbox processor appends `?inviteId=<guid>` automatically. The app resolves this universal/app link to `/settings/family-space/invites`.

Use the HTTPS universal/app-link URL here, not the custom `conscia://` scheme. The production default should stay:

```text
https://getconscia.com/open/family-invite
```

Before relying on invite links in store builds, run a web release so these association files are published:

```text
https://getconscia.com/.well-known/apple-app-site-association
https://getconscia.com/.well-known/assetlinks.json
```

### SES Email

These are required now for family invite email delivery:

#### `SES_FROM_EMAIL`

Usually `invites@getconscia.com`.

#### `SES_CONFIGURATION_SET`

Usually `conscia-production`. Confirm from stack outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name Conscia-Email \
  --query "Stacks[0].Outputs" \
  --output table
```

### Phase 2 Notes

- The API now supports the current app release and the previous app release.
- The app sends `X-Conscia-App-Version`, and the API can return `426 Upgrade Required` when the app falls behind the supported window.
- Keep normal backend changes additive within `v=1`.
- Introduce `v=2` only for real contract breaks.
- Subscription verification now fails closed. If Apple/Google validation is not configured, purchase verification requests will be rejected instead of granting fallback premium.
- Receipt OCR now fails closed. If no real OCR provider is configured, receipt scanning returns `503` instead of fake extracted data.

---

## Phase 3: Mobile Release Automation And Store Signing

This phase is only needed when CI should produce store-ready Android and iOS builds.

The current `release-app.yml` now targets low-risk distribution channels by default:

- Android uploads signed `.aab` releases to the Google Play `internal` track
- iOS uploads signed `.ipa` releases to TestFlight
- both artifacts are also preserved in GitHub Actions for debugging and manual recovery

Production rollout and store promotion are still manual after these uploads succeed.

### Firebase Client Files

#### `ANDROID_GOOGLE_SERVICES_JSON_BASE64`

```bash
base64 -i google-services.json | tr -d '\n' | gh secret set ANDROID_GOOGLE_SERVICES_JSON_BASE64 --repo nearlyheadlessarvie/conscia
```

#### `IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64`

```bash
base64 -i GoogleService-Info.plist | tr -d '\n' | gh secret set IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64 --repo nearlyheadlessarvie/conscia
```

#### `FIREBASE_OPTIONS_DART_BASE64`

Only needed if `app/lib/firebase_options.dart` is environment-specific and not committed.

### Android Signing And Deployment

#### `ANDROID_KEYSTORE_BASE64`

```bash
keytool -genkey -v \
  -keystore conscia-release.jks \
  -alias conscia \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

base64 -i conscia-release.jks | tr -d '\n' | gh secret set ANDROID_KEYSTORE_BASE64 --repo nearlyheadlessarvie/conscia
```

#### `ANDROID_KEYSTORE_PASSWORD`

#### `ANDROID_KEY_ALIAS`

#### `ANDROID_KEY_PASSWORD`

#### `GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON`

Service account JSON with Play Console release permissions.

The app workflow uses this to upload the signed bundle directly to the Play `internal` track.

### iOS Signing And Deployment

#### `APP_STORE_CONNECT_API_KEY_ID`

#### `APP_STORE_CONNECT_ISSUER_ID`

#### `APP_STORE_CONNECT_API_PRIVATE_KEY`

#### `IOS_CERTIFICATE_P12_BASE64`

#### `IOS_CERTIFICATE_PASSWORD`

#### `IOS_PROVISIONING_PROFILE_BASE64`

#### `IOS_BUNDLE_ID`

Usually `com.conscia.app`.

The app workflow uses these iOS secrets to sign the archive on a macOS runner and upload the resulting IPA to TestFlight.

How to confirm:

- Xcode -> Runner target -> Signing & Capabilities -> Bundle Identifier
- Apple Developer Portal -> Certificates, Identifiers & Profiles -> Identifiers -> App ID

The value must match the App ID used by the provisioning profile and the associated domains capability.

### Passkey Association Files

Passkeys now replace the old faux biometric toggle for Cognito-native Conscia accounts. Real devices need associated-domain metadata generated during the web release.

The web release uses these values to generate:

- `/.well-known/apple-app-site-association` for iOS universal links and passkeys
- `/.well-known/assetlinks.json` for Android app links and passkeys

`release-web.yml` has `REQUIRE_PASSKEY_ASSOCIATIONS=true`, so missing values fail the web release before deploy.

#### `APPLE_TEAM_ID`

Your Apple Developer Team ID. This is used to generate the `apple-app-site-association` file for iOS passkeys and universal links.

How to get it:

- Apple Developer Portal -> Membership details -> Team ID
- Or Xcode -> Settings -> Accounts -> select team -> Team ID

This is usually a 10-character alphanumeric value. It is not the App Store Connect issuer ID.

```bash
gh variable set APPLE_TEAM_ID --body "YOURTEAMID" --repo nearlyheadlessarvie/conscia
```

#### `ANDROID_PASSKEY_SHA256_CERT_FINGERPRINTS`

Comma-separated SHA-256 signing certificate fingerprints for the Android app. Include every fingerprint that should be trusted for passkeys and app links, for example release and Play App Signing fingerprints.

```bash
gh variable set ANDROID_PASSKEY_SHA256_CERT_FINGERPRINTS \
  --body "AA:BB:CC:...,11:22:33:..." \
  --repo nearlyheadlessarvie/conscia
```

You can get fingerprints with:

```bash
keytool -list -v -keystore conscia-release.jks -alias conscia
```

For Play-distributed builds, copy the production fingerprint from:

```text
Play Console -> your app -> Setup -> App integrity -> App signing -> App signing key certificate -> SHA-256 certificate fingerprint
```

If you use an upload key or local/internal builds, also include those fingerprints. For local Android app-link testing:

```bash
cd app/android
./gradlew signingReport
```

On Windows PowerShell:

```powershell
cd app/android
.\gradlew signingReport
```

---

## Bulk Push Helper

If you want to stage values locally before pushing them, keep the files untracked:

```text
.github/secrets.env
.github/variables.env
```

### Example `.github/variables.env`

```env
AWS_REGION=ap-southeast-1
CONSCIA_DOMAIN_NAME=getconscia.com
CONSCIA_WWW_DOMAIN_NAME=www.getconscia.com
CONSCIA_API_DOMAIN_NAME=api.getconscia.com
ROUTE53_HOSTED_ZONE_ID=ZXXXXXXXXXXXXX
API_BASE_URL=https://api.getconscia.com/api/
MOCK_AUTH=false
PUSH_NOTIFICATIONS_ENABLED=false
GOOGLE_PLAY_PACKAGE_NAME=com.getconscia.app
IOS_BUNDLE_ID=com.getconscia.app
SES_FROM_EMAIL=invites@getconscia.com
SES_CONFIGURATION_SET=conscia-production
FIREBASE_PROJECT_ID=conscia-production
INVITE_EMAIL_DEEP_LINK_BASE_URI=https://getconscia.com/open/family-invite
APPLE_TEAM_ID=YOURTEAMID
ANDROID_PASSKEY_SHA256_CERT_FINGERPRINTS=AA:BB:CC:...
```

### Push Script

```bash
REPO="nearlyheadlessarvie/conscia"

gh secret set --env-file .github/secrets.env --repo "$REPO"

while IFS='=' read -r key value; do
  [[ "$key" =~ ^#|^$ ]] && continue
  gh variable set "$key" --body "$value" --repo "$REPO"
done < .github/variables.env
```

---

## Release Strategy

Recommended release flow:

- Protect `main`
- Use short-lived feature branches
- Require PR review for merges
- Let `release-please` prepare reviewable release PRs from Conventional Commit history
- Tag deployable components independently:
  - `infra/vX.Y.Z`
  - `api/vX.Y.Z`
  - `web/vX.Y.Z`
  - `app/vX.Y.Z`
- When an app release PR is prepared, the repo automatically syncs:
  - `app/pubspec.yaml`
  - `src/Conscia.Api/appsettings*.json`
  - `src/Conscia.Api/Versioning/AppCompatibilityOptions.cs`
  - `release-matrix.md`

For the app, ship on a slower release train than API and web. Only introduce a `release/*` branch if you need to hotfix the store app while `main` continues moving.
