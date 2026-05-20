# GitHub Release Secrets Template

This file documents the GitHub Actions secrets and variables needed to release Conscia. Do not put real values in this file. Configure real values in GitHub repository settings under **Settings -> Secrets and variables -> Actions**.

## Required Now

| Name | Type | Used By | Notes |
|---|---|---|---|
| `AWS_DEPLOY_ROLE_ARN` | Secret | `release-infra.yml`, `release-api.yml`, `release-web.yml` | IAM role assumed through GitHub OIDC. Created by `Conscia-CiCd` as `ConsciaGitHubActionsRoleArn`. |

## Production Domain And AWS

| Name | Type | Used By | Notes |
|---|---|---|---|
| `AWS_REGION` | Variable | Release workflows | Home region. Use `ap-southeast-1`. |
| `CONSCIA_DOMAIN_NAME` | Variable | `release-infra.yml`, `release-api.yml`, `release-web.yml` | `getconscia.com`. Turns on domain-aware CDK resources. |
| `CONSCIA_WWW_DOMAIN_NAME` | Variable | `release-infra.yml`, `release-web.yml` | `www.getconscia.com`. Defaults to `www.<CONSCIA_DOMAIN_NAME>` in CDK if omitted. |
| `CONSCIA_API_DOMAIN_NAME` | Variable | `release-infra.yml`, `release-api.yml` | `api.getconscia.com`. Defaults to `api.<CONSCIA_DOMAIN_NAME>` in CDK if omitted. |
| `ROUTE53_HOSTED_ZONE_ID` | Variable | `release-infra.yml`, `release-api.yml`, `release-web.yml` | Existing hosted zone for `getconscia.com`. The current workflows read this from `vars`, so store it as a variable. |

## ACM Certificates

CDK now creates and validates certificates when `CONSCIA_DOMAIN_NAME` and `ROUTE53_HOSTED_ZONE_ID` are configured.

| Certificate | Region | Used By | Notes |
|---|---|---|---|
| Marketing/CloudFront certificate | `us-east-1` | `Conscia-Web` | CloudFront requires ACM certificates in `us-east-1`. Implemented with a DNS-validated certificate for `getconscia.com` and `www.getconscia.com`. |
| API certificate | `ap-southeast-1` | `Conscia-Compute` | Regional API Gateway custom domain certificate for `api.getconscia.com`. |

## Flutter Build-Time Config

| Name | Type | Used By | Notes |
|---|---|---|---|
| `API_BASE_URL` | Variable | `release-app.yml` / Flutter web app build | `https://api.getconscia.com/api/`. Keep the trailing slash. The app injects `?v=1` automatically. |
| `MOCK_AUTH` | Variable | `release-app.yml` | `false` for production. |
| `GOOGLE_SERVER_CLIENT_ID` | Secret | `release-app.yml` | Google web/server OAuth client ID used by native Google sign-in. |
| `PUSH_NOTIFICATIONS_ENABLED` | Variable | `release-app.yml` | `true` only after Firebase is fully configured. |

## API Runtime Secrets

These should ultimately live in AWS Secrets Manager or SSM Parameter Store and be injected into Lambda by CDK, not passed directly from GitHub into deployed code.

The runtime API contract is now:

- Canonical: query-string versioning, for example `/api/users/me?v=1`
- Secondary: `X-Api-Version: 1`
- App compatibility: current app release plus previous app release

| Name | Type | Used By | Notes |
|---|---|---|---|
| `AUTH_APP_JWT_SIGNING_KEY` | Secret | Future infra/API deploy | 32+ character signing key for app-issued JWTs used by social auth. Maps to `Auth__AppJwtSigningKey`. |
| `AUTH_GOOGLE_CLIENT_ID` | Secret | Future infra/API deploy | Google token audience. Maps to `Auth__Google__ClientId` or `Auth__Google__ClientIds__0`. |
| `AUTH_APPLE_CLIENT_ID` | Secret | Future infra/API deploy | Usually the iOS bundle ID. Maps to `Auth__Apple__ClientId`. |
| `APPLE_KEY_ID` | Secret | Future store/subscription validation | Maps to `Apple__KeyId` if Apple server API validation is enabled. |
| `APPLE_ISSUER_ID` | Secret | Future store/subscription validation | Maps to `Apple__IssuerId`. |
| `APPLE_PRIVATE_KEY` | Secret | Future store/subscription validation | Maps to `Apple__PrivateKey`. Preserve line breaks or store as base64. |
| `GOOGLE_PLAY_PACKAGE_NAME` | Variable | Future store/subscription validation | Maps to `GooglePlay__PackageName`. |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Secret | Future store/subscription validation | Maps to `GooglePlay__ServiceAccountJson`. |
| `FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON` | Secret | Future push delivery | Server-side FCM sender credential. Not needed while push delivery is no-op. |

## Firebase Client Config

Only needed when mobile Firebase is enabled in CI.

| Name | Type | Used By | Notes |
|---|---|---|---|
| `ANDROID_GOOGLE_SERVICES_JSON_BASE64` | Secret | `release-app.yml` | Writes to `app/android/app/google-services.json`. |
| `IOS_GOOGLE_SERVICE_INFO_PLIST_BASE64` | Secret | `release-app.yml` | Writes to `app/ios/Runner/GoogleService-Info.plist`. |
| `FIREBASE_OPTIONS_DART_BASE64` | Secret | `release-app.yml` | Optional if generated `app/lib/firebase_options.dart` is environment-specific and not committed. |

## Android Signing And Distribution

Only needed when CI starts producing store-ready Android releases.

| Name | Type | Used By | Notes |
|---|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | Secret | `release-app.yml` | Release keystore encoded as base64. |
| `ANDROID_KEYSTORE_PASSWORD` | Secret | `release-app.yml` | Keystore password. |
| `ANDROID_KEY_ALIAS` | Secret | `release-app.yml` | Release key alias. |
| `ANDROID_KEY_PASSWORD` | Secret | `release-app.yml` | Release key password. |
| `GOOGLE_PLAY_DEPLOY_SERVICE_ACCOUNT_JSON` | Secret | `release-app.yml` Play internal upload | Service account with Play Console release permissions. Can be same project as subscription validation, but keep permissions scoped. |

## iOS Signing And Distribution

Only needed when CI starts producing signed iOS releases.

| Name | Type | Used By | Notes |
|---|---|---|---|
| `APP_STORE_CONNECT_API_KEY_ID` | Secret | `release-app.yml` TestFlight upload | App Store Connect API key ID. |
| `APP_STORE_CONNECT_ISSUER_ID` | Secret | `release-app.yml` TestFlight upload | App Store Connect issuer ID. |
| `APP_STORE_CONNECT_API_PRIVATE_KEY` | Secret | `release-app.yml` TestFlight upload | Private key contents. Preserve line breaks or store as base64. |
| `IOS_CERTIFICATE_P12_BASE64` | Secret | `release-app.yml` | Signing certificate. |
| `IOS_CERTIFICATE_PASSWORD` | Secret | `release-app.yml` | Certificate password. |
| `IOS_PROVISIONING_PROFILE_BASE64` | Secret | `release-app.yml` | Provisioning profile. |
| `IOS_BUNDLE_ID` | Variable | `release-app.yml` | Example: `com.conscia.app`. |

## SES Email

CDK creates an SES domain identity and configuration set when production domain vars are configured.

| Name | Type | Used By | Notes |
|---|---|---|---|
| `SES_FROM_EMAIL` | Variable | Future API/outbox email sender | CDK currently outputs `invites@getconscia.com`. |
| `SES_CONFIGURATION_SET` | Variable | Future API/outbox email sender | CDK currently creates `conscia-production`. |
