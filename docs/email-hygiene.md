# Email Hygiene

This is intentionally narrow. It covers hard bounces, complaints, and direct recipient requests for transactional family invites and future non-auth notification emails. It is not a marketing preference center, and it does not change Cognito account-security email behavior.

## Current Behavior

- `EmailSuppressions` stores normalized recipient addresses suppressed for `HardBounce`, `Complaint`, or `RecipientRequest`.
- Family invite outbox processing checks `EmailSuppressions` before sending email.
- Suppressed invite recipients do not receive invite email, and the outbox event is still marked processed so delivery retries do not loop.
- Registered suppressed recipients can still receive in-app alerts and push notifications for the invite.
- Brevo transactional webhooks are not wired here. SES hardening is the target of this change.

## Recipient Requests

If a recipient explicitly asks not to receive transactional invite or non-auth notification email, add the normalized address to `EmailSuppressions` with `Reason = RecipientRequest` and `Source = Support`. The same send guard applies regardless of suppression reason.

Example manual suppression:

```bash
aws dynamodb put-item \
  --table-name EmailSuppressions \
  --item '{"PK":{"S":"EMAIL#recipient@example.com"},"Email":{"S":"recipient@example.com"},"Reason":{"S":"RecipientRequest"},"Source":{"S":"Support"},"SuppressedAt":{"S":"2026-06-02T00:00:00Z"}}'
```

## SES Production Readiness

`Conscia-Email` configures the SES configuration set `conscia-production` with:

- configuration-set suppression reasons `BOUNCE` and `COMPLAINT`;
- an EventBridge event destination for `BOUNCE` and `COMPLAINT` sending events;
- an EventBridge rule for `Email Bounced` and `Email Complaint Received`;
- the existing `conscia-outbox-processor` Lambda as the event target, so no additional worker Lambda, SNS topic, or SQS queue is introduced.

This is the lowest-cost routing pattern that still ingests actionable SES events into the application suppression table. Costs are event-driven: EventBridge events and Lambda invocations only occur when SES emits matching bounce/complaint events. The only standing resource added for storage is the on-demand `EmailSuppressions` DynamoDB table.

SES account-level suppression is regional and account-wide. When SES sending is reintroduced in the target region, enable it explicitly:

```bash
aws sesv2 put-account-suppression-attributes --suppressed-reasons BOUNCE COMPLAINT
aws sesv2 get-account
```

Use the `conscia-production` configuration set for transactional sends so the configuration-set suppression and EventBridge route both apply.

## Signup And Email Abuse Controls

Public unauthenticated endpoints that can trigger account-security email are protected before Cognito is called:

- mobile signup, resend-confirmation, and password-reset-start requests include a reCAPTCHA token generated for the specific action;
- the API verifies that token server-side against configured Conscia mobile site keys and a configurable score threshold;
- direct unauthenticated Cognito `SignUp` calls are rejected by the Cognito pre-signup Lambda unless the request includes server-only client metadata added by the API registration service.

The reCAPTCHA API key is loaded from Secrets Manager. Mobile site keys are public app build configuration.

## Email Authentication

`Conscia-Email` also provisions SES domain-authentication DNS in Route53 when `DomainSettings` are configured:

- Easy DKIM is enabled for the `getconscia.com` SES domain identity;
- three SES DKIM CNAME records are published from the SES identity tokens;
- `feedback.getconscia.com` is configured as the custom MAIL FROM domain;
- `feedback.getconscia.com` publishes the SES regional MX record and SPF TXT record;
- `_dmarc.getconscia.com` publishes a monitoring-only DMARC policy with aggregate reports sent to a Conscia-owned mailbox by default.

Keep DMARC at `p=none` while validating low-volume transactional traffic across all legitimate senders. Move to a stricter policy only after legitimate senders are confirmed to pass authentication.

For an SES production access request, summarize the implemented controls as:

- We send transactional email only for user-initiated account/family workflows, not marketing.
- We maintain an application-level suppression table for hard bounces, complaints, and direct recipient requests.
- Family invite and future non-auth transactional outbox sends check that table before delivery and do not retry suppressed recipients.
- SES bounce and complaint events are routed through EventBridge into the existing outbox Lambda, which upserts the suppression table.
- SES account-level suppression is enabled or verified for `BOUNCE` and `COMPLAINT` in the sending region before SES traffic resumes.
- SES sends use a verified domain identity with Easy DKIM, custom MAIL FROM SPF, and DMARC monitoring.
- Public signup and auth-email trigger endpoints use server-side reCAPTCHA assessment, and direct Cognito sign-up calls without API-added private metadata are rejected.

## Monitoring

To keep baseline cost low, this change does not add paid CloudWatch alarms by default. Monitor:

- SES account reputation and bounce/complaint metrics in the SES console or CloudWatch;
- EventBridge rule metrics for failed invocations;
- `/aws/lambda/conscia-outbox-processor` logs for `Suppressed email ... after SES ...` entries.

If SES volume grows, add CloudWatch alarms for SES bounce/complaint rate and EventBridge failed invocations.
