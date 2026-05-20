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

This phase is for production auth, app compatibility policy, push delivery, and store-validation credentials. These values should ultimately live in AWS Secrets Manager or SSM Parameter Store and be injected by CDK, not permanently sourced from GitHub Actions secrets.

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

#### `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

Service account JSON for Play purchase validation.

### Push Delivery

#### `FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON`

Firebase Admin SDK JSON, only needed once server-side push delivery is implemented.

### SES Email

These are needed once the email stack is live:

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

---

## Phase 3: Mobile Release Automation And Store Signing

This phase is only needed when CI should produce store-ready Android and iOS builds.

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

### iOS Signing And Deployment

#### `APP_STORE_CONNECT_API_KEY_ID`

#### `APP_STORE_CONNECT_ISSUER_ID`

#### `APP_STORE_CONNECT_API_PRIVATE_KEY`

#### `IOS_CERTIFICATE_P12_BASE64`

#### `IOS_CERTIFICATE_PASSWORD`

#### `IOS_PROVISIONING_PROFILE_BASE64`

#### `IOS_BUNDLE_ID`

Usually `com.conscia.app`.

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
