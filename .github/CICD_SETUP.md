# Conscia CI/CD Setup — Where to Get Every Value

This file documents how to obtain each secret and variable required before GitHub Actions can deploy to AWS. Work through the sections in order — some values only exist after earlier steps complete.

---

## Prerequisites

- AWS account with an IAM user that has admin access (temporary — only needed for bootstrap)
- Domain registered and a Route 53 hosted zone for `getconscia.com`
- GitHub CLI: `brew install gh && gh auth login`
- AWS CLI: `brew install awscli && aws configure`
- CDK CLI: `npm install -g aws-cdk`

---

## Step 1 — Bootstrap CDK and Deploy the CiCd Stack

Run these locally with your admin IAM credentials. Everything after this uses the role created here.

```bash
# Get your AWS account ID
aws sts get-caller-identity --query Account --output text

# Bootstrap CDK (creates S3 bucket + ECR repo for CDK assets)
cd infra
cdk bootstrap aws://YOUR_ACCOUNT_ID/ap-southeast-1

# Deploy only the CiCd stack — creates the GitHub Actions IAM role
cdk deploy Conscia-CiCd

# Capture the role ARN (you need this for AWS_DEPLOY_ROLE_ARN below)
aws cloudformation describe-stacks \
  --stack-name Conscia-CiCd \
  --query "Stacks[0].Outputs[?ExportName=='ConsciaGitHubActionsRoleArn'].OutputValue" \
  --output text
```

---

## Required Now

### `AWS_DEPLOY_ROLE_ARN` — Secret

**How to get it:** Output of `cdk deploy Conscia-CiCd` above. Looks like:
`arn:aws:iam::123456789012:role/conscia-github-actions`

```bash
gh secret set AWS_DEPLOY_ROLE_ARN \
  --body "arn:aws:iam::YOUR_ACCOUNT_ID:role/conscia-github-actions" \
  --repo nearlyheadlessarvie/conscia
```

---

## Production Domain and AWS

### `AWS_REGION` — Variable

**Value:** `ap-southeast-1` (Singapore — already hardcoded as the default in CDK, but set it explicitly so workflows don't rely on the fallback).

```bash
gh variable set AWS_REGION --body "ap-southeast-1" --repo nearlyheadlessarvie/conscia
```

---

### `CONSCIA_DOMAIN_NAME` — Variable

**Value:** `getconscia.com`

```bash
gh variable set CONSCIA_DOMAIN_NAME --body "getconscia.com" --repo nearlyheadlessarvie/conscia
```

---

### `CONSCIA_WWW_DOMAIN_NAME` — Variable

**Value:** `www.getconscia.com`

```bash
gh variable set CONSCIA_WWW_DOMAIN_NAME --body "www.getconscia.com" --repo nearlyheadlessarvie/conscia
```

---

### `CONSCIA_API_DOMAIN_NAME` — Variable

**Value:** `api.getconscia.com`

```bash
gh variable set CONSCIA_API_DOMAIN_NAME --body "api.getconscia.com" --repo nearlyheadlessarvie/conscia
```

---

### `ROUTE53_HOSTED_ZONE_ID` — Variable

**How to get it:** Look up your existing hosted zone for `getconscia.com`.

```bash
aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='getconscia.com.'].Id" \
  --output text
# Returns something like: /hostedzone/Z04XXXXXXXXXXXXXXXXX
# Strip the /hostedzone/ prefix — use just: Z04XXXXXXXXXXXXXXXXX
```

```bash
gh variable set ROUTE53_HOSTED_ZONE_ID --body "Z04XXXXXXXXXXXXXXXXX" --repo nearlyheadlessarvie/conscia
```

---

## Flutter Build-Time Config

These are needed when `release-app.yml` is wired up for store builds.

### `API_BASE_URL` — Variable

**Value:** `https://api.getconscia.com/api/v1/` (trailing slash required)

```bash
gh variable set API_BASE_URL --body "https://api.getconscia.com/api/v1/" --repo nearlyheadlessarvie/conscia
```

---

### `MOCK_AUTH` — Variable

**Value:** `false` for production.

```bash
gh variable set MOCK_AUTH --body "false" --repo nearlyheadlessarvie/conscia
```

---

### `GOOGLE_SERVER_CLIENT_ID` — Secret

**How to get it:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/) → your project → APIs & Services → Credentials
2. Create or find an OAuth 2.0 Client ID of type **Web application**
3. Copy the **Client ID** (not the secret — just the ID, ends in `.apps.googleusercontent.com`)

```bash
gh secret set GOOGLE_SERVER_CLIENT_ID --body "YOUR_CLIENT_ID.apps.googleusercontent.com" --repo nearlyheadlessarvie/conscia
```

---

### `PUSH_NOTIFICATIONS_ENABLED` — Variable

**Value:** `false` until Firebase is fully configured. Set to `true` after completing the Firebase section below.

```bash
gh variable set PUSH_NOTIFICATIONS_ENABLED --body "false" --repo nearlyheadlessarvie/conscia
```

---

## API Runtime Secrets

> These are injected into Lambda at deploy time. They should ultimately live in AWS Secrets Manager or SSM Parameter Store — CDK reads them from there and injects into Lambda environment. The values below are what you'd put into SSM, not directly into GitHub.

### `AUTH_APP_JWT_SIGNING_KEY` — Secret

**How to get it:** Generate a random 32+ character string. This is your own signing key — keep it secret and consistent (changing it invalidates all active app-issued JWTs).

```bash
# Generate a secure random key
openssl rand -base64 32

gh secret set AUTH_APP_JWT_SIGNING_KEY --body "YOUR_GENERATED_KEY" --repo nearlyheadlessarvie/conscia
```

---

### `AUTH_GOOGLE_CLIENT_ID` — Secret

**How to get it:** Same OAuth 2.0 Web Client ID as `GOOGLE_SERVER_CLIENT_ID` above. This is used by the API to validate Google ID tokens (the audience claim must match).

```bash
gh secret set AUTH_GOOGLE_CLIENT_ID --body "YOUR_CLIENT_ID.apps.googleusercontent.com" --repo nearlyheadlessarvie/conscia
```

---

### `AUTH_APPLE_CLIENT_ID` — Secret

**How to get it:** Your iOS app's bundle ID (e.g. `com.conscia.app`). This is the Service ID Apple uses for Sign in with Apple token audience validation.
- Find it in [Apple Developer Portal](https://developer.apple.com/account/) → Certificates, Identifiers & Profiles → Identifiers

```bash
gh secret set AUTH_APPLE_CLIENT_ID --body "com.conscia.app" --repo nearlyheadlessarvie/conscia
```

---

### `APPLE_KEY_ID` — Secret

**How to get it:** Only needed if you implement server-side Apple receipt validation.
- Apple Developer Portal → Certificates, Identifiers & Profiles → Keys → create a key with **In-App Purchase** capability
- The Key ID is shown after creation (10-character alphanumeric string)

```bash
gh secret set APPLE_KEY_ID --body "XXXXXXXXXX" --repo nearlyheadlessarvie/conscia
```

---

### `APPLE_ISSUER_ID` — Secret

**How to get it:**
- App Store Connect → Users and Access → Integrations → App Store Connect API
- Your Issuer ID is shown at the top of that page (UUID format)

```bash
gh secret set APPLE_ISSUER_ID --body "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" --repo nearlyheadlessarvie/conscia
```

---

### `APPLE_PRIVATE_KEY` — Secret

**How to get it:** Downloaded when you created the Key above. It's a `.p8` file. Paste the full contents including the `-----BEGIN PRIVATE KEY-----` header and footer. Preserve newlines.

```bash
gh secret set APPLE_PRIVATE_KEY < AuthKey_XXXXXXXXXX.p8 --repo nearlyheadlessarvie/conscia
```

---

### `GOOGLE_PLAY_PACKAGE_NAME` — Variable

**Value:** Your Android app's package name, e.g. `com.conscia.app`. Find it in `app/android/app/build.gradle` as `applicationId`.

```bash
gh variable set GOOGLE_PLAY_PACKAGE_NAME --body "com.conscia.app" --repo nearlyheadlessarvie/conscia
```

---

### `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` — Secret

**How to get it:** Used for server-side Play purchase validation.
1. Google Cloud Console → IAM → Service Accounts → create a service account
2. Grant it the **Pub/Sub Subscriber** and minimal roles needed
3. Link it in Play Console: Setup → API access → Link to your Google Cloud project → grant the service account access
4. Create a JSON key for the service account and download it

```bash
gh secret set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON < service-account.json --repo nearlyheadlessarvie/conscia
```

---

### `FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON` — Secret

**How to get it:** Only needed for server-side push notification delivery (FCM).
1. Firebase Console → your project → Project Settings → Service accounts
2. Click **Generate new private key** → downloads a JSON file

```bash
gh secret set FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON < firebase-adminsdk.json --repo nearlyheadlessarvie/conscia
```

---

## Firebase Client Config

Only needed when the mobile app build in CI enables Firebase.

### `ANDROID_GOOGLE_SERVICES_JSON_BASE64` — Secret

**How to get it:**
1. Firebase Console → Project Settings → Your apps → Android app → Download `google-services.json`

```bash
base64 -i google-services.json | tr -d '\n' | gh secret set ANDROID_GOOGLE_SERVICES_JSON_BASE64 --repo nearlyheadlessarvie/conscia
```

---

### `IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64` — Secret

**How to get it:**
1. Firebase Console → Project Settings → Your apps → iOS app → Download `GoogleService-Info.plist`

```bash
base64 -i GoogleService-Info.plist | tr -d '\n' | gh secret set IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64 --repo nearlyheadlessarvie/conscia
```

---

### `FIREBASE_OPTIONS_DART_BASE64` — Secret

**How to get it:** Only needed if `app/lib/firebase_options.dart` is environment-specific and not committed. If it is committed, skip this.

```bash
base64 -i lib/firebase_options.dart | tr -d '\n' | gh secret set FIREBASE_OPTIONS_DART_BASE64 --repo nearlyheadlessarvie/conscia
```

---

## Android Signing and Distribution

Only needed when CI should produce store-ready Android releases.

### `ANDROID_KEYSTORE_BASE64` — Secret

**How to get it:** If you don't have a release keystore yet, generate one:

```bash
keytool -genkey -v \
  -keystore conscia-release.jks \
  -alias conscia \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# Then encode it
base64 -i conscia-release.jks | tr -d '\n' | gh secret set ANDROID_KEYSTORE_BASE64 --repo nearlyheadlessarvie/conscia
```

> **Warning:** Back up `conscia-release.jks` securely. You cannot re-upload to the Play Store with a different key once the app is published.

---

### `ANDROID_KEYSTORE_PASSWORD` — Secret

**Value:** The password you chose when running `keytool` above.

```bash
gh secret set ANDROID_KEYSTORE_PASSWORD --body "YOUR_KEYSTORE_PASSWORD" --repo nearlyheadlessarvie/conscia
```

---

### `ANDROID_KEY_ALIAS` — Secret

**Value:** `conscia` (or whatever alias you used in `keytool -alias`).

```bash
gh secret set ANDROID_KEY_ALIAS --body "conscia" --repo nearlyheadlessarvie/conscia
```

---

### `ANDROID_KEY_PASSWORD` — Secret

**Value:** The key password (may be the same as the keystore password).

```bash
gh secret set ANDROID_KEY_PASSWORD --body "YOUR_KEY_PASSWORD" --repo nearlyheadlessarvie/conscia
```

---

### `GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON` — Secret

**How to get it:** A service account with Play Console **Release Manager** role.
1. Play Console → Setup → API access → Link to Google Cloud project
2. Grant the service account **Release Manager** in Play Console
3. Create a JSON key in Google Cloud Console → download it

```bash
gh secret set GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON < play-deploy-sa.json --repo nearlyheadlessarvie/conscia
```

---

## iOS Signing and Distribution

Only needed when CI should produce signed iOS releases.

### `APP_STORE_CONNECT_API_KEY_ID` — Secret

**How to get it:**
1. App Store Connect → Users and Access → Integrations → App Store Connect API
2. Generate a new API key with **Developer** role (or higher)
3. The **Key ID** is shown immediately (10-character string)

```bash
gh secret set APP_STORE_CONNECT_API_KEY_ID --body "XXXXXXXXXX" --repo nearlyheadlessarvie/conscia
```

---

### `APP_STORE_CONNECT_ISSUER_ID` — Secret

**How to get it:** Same page as above — the Issuer ID is shown at the top (UUID format).

```bash
gh secret set APP_STORE_CONNECT_ISSUER_ID --body "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" --repo nearlyheadlessarvie/conscia
```

---

### `APP_STORE_CONNECT_API_PRIVATE_KEY` — Secret

**How to get it:** Downloaded once when you created the API key above. It's a `.p8` file. You only get one download — save it securely.

```bash
gh secret set APP_STORE_CONNECT_API_PRIVATE_KEY < AuthKey_XXXXXXXXXX.p8 --repo nearlyheadlessarvie/conscia
```

---

### `IOS_CERTIFICATE_P12_BASE64` — Secret

**How to get it:**
1. Xcode → Settings → Accounts → Manage Certificates → create an **Apple Distribution** certificate
2. Right-click it in Keychain Access → Export → save as `.p12` with a password

```bash
base64 -i distribution.p12 | tr -d '\n' | gh secret set IOS_CERTIFICATE_P12_BASE64 --repo nearlyheadlessarvie/conscia
```

---

### `IOS_CERTIFICATE_PASSWORD` — Secret

**Value:** The password you set when exporting the `.p12` above.

```bash
gh secret set IOS_CERTIFICATE_PASSWORD --body "YOUR_P12_PASSWORD" --repo nearlyheadlessarvie/conscia
```

---

### `IOS_PROVISIONING_PROFILE_BASE64` — Secret

**How to get it:**
1. Apple Developer Portal → Certificates, Identifiers & Profiles → Profiles
2. Create an **App Store** distribution profile for your bundle ID
3. Download the `.mobileprovision` file

```bash
base64 -i ConsciaDist.mobileprovision | tr -d '\n' | gh secret set IOS_PROVISIONING_PROFILE_BASE64 --repo nearlyheadlessarvie/conscia
```

---

### `IOS_BUNDLE_ID` — Variable

**Value:** Your app's bundle identifier. Find it in `app/ios/Runner.xcodeproj` or Xcode → Runner target → General → Bundle Identifier.

```bash
gh variable set IOS_BUNDLE_ID --body "com.conscia.app" --repo nearlyheadlessarvie/conscia
```

---

## SES Email

CDK creates the SES domain identity automatically when `CONSCIA_DOMAIN_NAME` is set. These variables tell the API which address to send from. Set them after the infra deploy runs at least once.

### `SES_FROM_EMAIL` — Variable

**Value:** CDK outputs `invites@getconscia.com` — use that unless you want a different sender address.

```bash
gh variable set SES_FROM_EMAIL --body "invites@getconscia.com" --repo nearlyheadlessarvie/conscia
```

---

### `SES_CONFIGURATION_SET` — Variable

**Value:** CDK creates `conscia-production` — check the `Conscia-Email` stack output to confirm.

```bash
aws cloudformation describe-stacks \
  --stack-name Conscia-Email \
  --query "Stacks[0].Outputs" \
  --output table

gh variable set SES_CONFIGURATION_SET --body "conscia-production" --repo nearlyheadlessarvie/conscia
```

---

## Bulk Push All at Once

Once you have all your values, fill in the two files below and run the push script. **Never commit these files.**

Add both to `.gitignore`:

```
.github/secrets.env
.github/variables.env
```

### `.github/secrets.env`

```env
AWS_DEPLOY_ROLE_ARN=arn:aws:iam::ACCOUNT_ID:role/conscia-github-actions
AUTH_APP_JWT_SIGNING_KEY=REPLACE_WITH_32_CHAR_RANDOM_STRING
AUTH_GOOGLE_CLIENT_ID=REPLACE.apps.googleusercontent.com
AUTH_APPLE_CLIENT_ID=com.getconscia.app
APPLE_KEY_ID=XXXXXXXXXX
APPLE_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPLE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\nREPLACE\n-----END PRIVATE KEY-----
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
ANDROID_KEYSTORE_BASE64=REPLACE_WITH_BASE64_OF_JKS
ANDROID_KEYSTORE_PASSWORD=REPLACE
ANDROID_KEY_ALIAS=conscia
ANDROID_KEY_PASSWORD=REPLACE
GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
APP_STORE_CONNECT_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APP_STORE_CONNECT_API_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\nREPLACE\n-----END PRIVATE KEY-----
IOS_CERTIFICATE_P12_BASE64=REPLACE_WITH_BASE64_OF_P12
IOS_CERTIFICATE_PASSWORD=REPLACE
IOS_PROVISIONING_PROFILE_BASE64=REPLACE_WITH_BASE64_OF_MOBILEPROVISION
GOOGLE_SERVER_CLIENT_ID=REPLACE.apps.googleusercontent.com
ANDROID_GOOGLE_SERVICES_JSON_BASE64=REPLACE_WITH_BASE64
IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64=REPLACE_WITH_BASE64
FIREBASE_OPTIONS_DART_BASE64=REPLACE_WITH_BASE64
```

### `.github/variables.env`

```env
AWS_REGION=ap-southeast-1
CONSCIA_DOMAIN_NAME=getconscia.com
CONSCIA_WWW_DOMAIN_NAME=www.getconscia.com
CONSCIA_API_DOMAIN_NAME=api.getconscia.com
ROUTE53_HOSTED_ZONE_ID=ZXXXXXXXXXXXXX
API_BASE_URL=https://api.getconscia.com/api/v1/
MOCK_AUTH=false
PUSH_NOTIFICATIONS_ENABLED=false
GOOGLE_PLAY_PACKAGE_NAME=com.getconscia.app
IOS_BUNDLE_ID=com.getconscia.app
SES_FROM_EMAIL=invites@getconscia.com
SES_CONFIGURATION_SET=conscia-production
```

### Push script

```bash
REPO="nearlyheadlessarvie/conscia"

# Secrets — native bulk support
gh secret set --env-file .github/secrets.env --repo "$REPO"

# Variables — loop (no native bulk support)
while IFS='=' read -r key value; do
  [[ "$key" =~ ^#|^$ ]] && continue
  gh variable set "$key" --body "$value" --repo "$REPO"
done < .github/variables.env

echo "Done."
```

---

## Verify Everything Is Set

```bash
REPO="nearlyheadlessarvie/conscia"
echo "=== Secrets ===" && gh secret list --repo "$REPO"
echo "=== Variables ===" && gh variable list --repo "$REPO"
```
