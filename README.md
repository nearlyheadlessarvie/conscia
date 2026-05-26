# Conscia

Conscia is a mobile-first financial coaching product with a Flutter app, a .NET 8 API, an Astro marketing site, and AWS CDK infrastructure. This file is the canonical implemented-state document for the repo as of 2026-05-26.

## Architecture

- `app/`: Flutter client for iOS and Android using Riverpod, GoRouter, Dio, and Material 3.
- `src/Conscia.Api`: ASP.NET 8 minimal API, production-hosted on Lambda behind API Gateway.
- `src/Conscia.Application`: service layer, DTOs, validators, trigger evaluators, and business rules.
- `src/Conscia.Infrastructure`: DynamoDB repositories plus Cognito, SES, S3, SQS, Firebase, Apple, Google Play, OCR, and exchange-rate integrations.
- `src/Conscia.AI`: Ollama-backed local AI and Bedrock-backed production AI services.
- `src/Conscia.OutboxProcessor`: background Lambda for outbox-driven side effects.
- `src/Conscia.RecurringProcessor`: scheduled Lambda for recurring transaction generation.
- `src/Conscia.PatternAggregator`: scheduled Lambda for insight and purchase-pattern aggregation.
- `infra/src/Conscia.Infra`: CDK stacks for data, storage, auth, compute, email, web, AI queueing, observability, and CI/CD wiring.
- `web/`: Astro marketing site with static pages plus `.well-known` generation support for passkey association files.

## Implemented Product Surface

### Mobile app

- Onboarding: sign up, sign in, email confirmation, profile capture, suggested budgets, and session-expired recovery.
- Auth: Cognito-backed email/password in production, native Google sign-in, native Apple sign-in, and Cognito WebAuthn passkeys.
- Dashboard: budget summary, budget trends, regret prompts, recent transactions, alerts, and journey-led sections.
- Transactions: create, edit, delete, filter, voice-assisted parsing, recent-category shortcuts, and regret feedback.
- Budgets: create, edit, delete, overview, premium gating, and suggested-budget flows.
- AI assistant: pre-purchase guidance, reflection flows, personality intensity, and budget context cards.
- Insights: summary, merchant trends, category trends, drilldowns, and feed composition.
- Family space: setup, invites, members, ownership transfer, sharing scopes, and pending-invite handling.
- Receipts: premium-gated scan and review flow, backed by real OCR in production and stub OCR only in development.
- Settings: profile, service status, category management, subscription UI, export/share fallback, admin entitlement screens, and passkey setup.
- Conscience Journey: XP, levels, events, glyphs, level-up UI, and family journey context.

### API and domain behavior

- Query-versioned API contract on `?v=1` with health endpoints and app compatibility headers.
- Auth endpoints for register, confirm, resend confirmation, login, refresh, Google, Apple, and passkey flows.
- CRUD endpoints for users, transactions, recurring schedules, budgets, categories, alerts, family space, subscriptions, admin entitlements, push device tokens, AI interactions, suggestions, exchange rates, receipts, and journey events.
- DynamoDB is the primary data store. Hot-path relational/RDS references in old docs are no longer current.
- Outbox pattern is active for side effects and async projections.
- Budget warnings, cooling-off suggestions, repeated regret detection, not-sure streaks, and reflection follow-ups are implemented as trigger evaluators.
- Subscription handling includes Apple verification, App Store Server Notifications V2 ingestion, Google Play validation, lifetime premium overrides, and admin reviewer/demo provisioning.

### Web and release surfaces

- Marketing site covers hero, features, pricing, roadmap, terms, privacy, and account deletion pages.
- Release automation is component-based via Conventional Commits and release-please tags for `app`, `api`, `infra`, and `web`.
- App release workflows build signed Android and iOS artifacts and publish to internal/TestFlight channels.
- API and infra release workflows publish Lambda assets before deploy and run tests before shipping.

## Production Infrastructure

- Data: DynamoDB tables for control plane, transactions, recurring schedules, AI interactions, outbox events, alerts, weekly insights, purchase patterns, monthly category spends, push tokens, and journey state.
- Storage: private S3 bucket for receipt and user-upload assets.
- Auth: Cognito user pool and client, including WebAuthn support.
- Compute: non-VPC Lambda API plus separate Lambdas for outbox, recurring generation, and pattern aggregation.
- AI: Bedrock for production completions, SQS for queued AI work, and Textract for OCR.
- Observability: CloudWatch log groups plus OpenTelemetry and Serilog wiring.
- Web: S3 + CloudFront + Route53 aliases and ACM certificates.
- Email: SES domain identity, Easy DKIM DNS records, custom MAIL FROM DNS, and DMARC DNS managed in CDK.

## Audit Notes

### Dev/test-only implementations still present but not release-facing

- `MockAuthService`, `StubOcrService`, `NoopInviteEmailSender`, and `NoopPushNotificationSender` are only wired in development or when mock auth is explicitly enabled.
- `story-demo` seed data and reviewer/demo tooling remain intentional local/admin tools, not production runtime behavior.
- Marketing `mock-card` naming in `web/src` is cosmetic CSS naming, not fake runtime behavior.

### Production-safety changes made in this audit

- Infra publish assets now fail fast when missing instead of silently deploying placeholder Lambda bundles. Placeholder assets are only available when `CONSCIA_ALLOW_PLACEHOLDER_ASSETS=true` is explicitly set.
- SES DNS is now modeled more completely in Route53:
  - Easy DKIM CNAME records from the SES identity
  - custom MAIL FROM domain on `feedback.<root-domain>` by default
  - MAIL FROM MX record to `feedback-smtp.<region>.amazonses.com`
  - MAIL FROM SPF TXT record
  - root DMARC TXT record
- Optional iCloud inbox DNS can now be materialized through GitHub/AWS environment variables, so inbox routing and SES outbox routing can coexist without sharing the same MAIL FROM subdomain.
- The leftover Android Gradle placeholder comment about application id was removed because the release package id is already finalized as `com.getconscia.app.ai`.

## Runtime and Deployment Inputs

### Core production variables

- Domain: `CONSCIA_DOMAIN_NAME`, `CONSCIA_WWW_DOMAIN_NAME`, `CONSCIA_API_DOMAIN_NAME`, `ROUTE53_HOSTED_ZONE_ID`
- API auth: `AUTH_APP_JWT_SIGNING_KEY`, `AUTH_GOOGLE_CLIENT_ID`, `AUTH_APPLE_CLIENT_ID`
- Apple subscription validation: `APPLE_KEY_ID`, `APPLE_ISSUER_ID`, `APPLE_PRIVATE_KEY`
- Google Play: `GOOGLE_PLAY_PACKAGE_NAME`, `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- Firebase delivery: `FIREBASE_ADMIN_SERVICE_ACCOUNT_JSON`, `FIREBASE_PROJECT_ID`
- Invite email runtime: `SES_FROM_EMAIL`, `SES_CONFIGURATION_SET`, `INVITE_EMAIL_DEEP_LINK_BASE_URI`

### Email/DNS variables added for this audit

- `CONSCIA_SES_MAIL_FROM_SUBDOMAIN`
  - default: `feedback`
- `CONSCIA_DMARC_RECORD_NAME`
  - default: `_dmarc`
- `CONSCIA_DMARC_VALUE`
  - default: `v=DMARC1; p=quarantine; adkim=s; aspf=s; pct=100`
- `ICLOUD_INBOX_MX_RECORDS_JSON`
  - JSON array of `{ "priority": 10, "host": "..." }`
- `ICLOUD_INBOX_TXT_RECORDS_JSON`
  - JSON array of `{ "name": "@", "value": "..." }`
- `ICLOUD_INBOX_CNAME_RECORDS_JSON`
  - JSON array of `{ "name": "sig1._domainkey", "value": "..." }`

## Local Development

### Prerequisites

- `.NET 8 SDK`
- `Flutter`
- `Node.js 20+`
- `Docker`

### Typical local boot

```bash
docker compose up -d
dotnet run --project tools/DynamoSetup
dotnet run --project tools/Seeder
dotnet run --project src/Conscia.Api
cd app && flutter pub get && dart run build_runner build --delete-conflicting-outputs && flutter run
cd web && npm install && npm run dev
```

### Focused test commands

```bash
dotnet test tests/Conscia.Tests.Unit
dotnet test tests/Conscia.Tests.Integration
dotnet test infra/tests/Conscia.Infra.Tests
cd app && flutter test
cd web && npm test
```

## Manual Verification: SES + Route53 + iCloud

This repo now contains enough structure for SES outbox DNS and iCloud inbox DNS, but iCloud still requires manual record values from Apple’s Custom Email Domain UI.

### 1. Deploy infra with domain variables

Run the normal `infra` release flow or:

```bash
dotnet publish src/Conscia.Api -c Release -r linux-arm64 --self-contained -o publish/api
dotnet publish src/Conscia.OutboxProcessor -c Release -r linux-arm64 --self-contained -o publish/outbox
dotnet publish src/Conscia.RecurringProcessor -c Release -r linux-arm64 --self-contained -o publish/recurring-processor
dotnet publish src/Conscia.PatternAggregator -c Release -r linux-arm64 --self-contained -o publish/pattern-aggregator
cd infra
dotnet test
cdk deploy --all
```

### 2. Verify SES state in AWS

- In SES, confirm the domain identity exists for the root domain.
- Confirm DKIM status is verified.
- Confirm the custom MAIL FROM domain is `feedback.<root-domain>` or your configured override.
- Confirm MAIL FROM status is verified.
- If the AWS account is still in the SES sandbox, request production access before relying on invite delivery.

### 3. Populate iCloud inbox records from Apple

According to Apple’s Custom Email Domain setup flow, the exact MX/TXT/CNAME values are provided during domain onboarding in iCloud, not derived from this repo. Take the record set Apple shows and place it into:

- `ICLOUD_INBOX_MX_RECORDS_JSON`
- `ICLOUD_INBOX_TXT_RECORDS_JSON`
- `ICLOUD_INBOX_CNAME_RECORDS_JSON`

Then redeploy `Conscia-Email`.

### 4. Verify Route53 records

- Root MX should point at the iCloud hosts Apple supplied.
- Root TXT/CNAME records should match Apple’s verification and DKIM instructions.
- `feedback.<root-domain>` must have exactly one SES MX record and one SES SPF TXT record.
- `_dmarc.<root-domain>` should resolve to the configured DMARC policy.

### 5. Prove the mail paths

- Send a family invite from the app or API and confirm SES accepts the message.
- Send a normal email to an inbox address on the custom domain and confirm it lands in iCloud Mail.
- Inspect message headers on an invite email and confirm DKIM passes and the return path uses the MAIL FROM subdomain.

## Primary Source References Used In This Audit

- AWS SES Easy DKIM: https://docs.aws.amazon.com/ses/latest/dg/send-email-authentication-dkim-easy.html
- AWS SES custom MAIL FROM: https://docs.aws.amazon.com/ses/latest/dg/mail-from.html
- AWS CloudFormation `AWS::SES::EmailIdentity`: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ses-emailidentity.html
- Apple Custom Email Domain overview: https://support.apple.com/en-us/102540
- Apple iCloud custom domain setup guide: https://support.apple.com/en-euro/guide/icloud/mm0e4339d289/icloud
