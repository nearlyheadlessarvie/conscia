# Email Hygiene

This is intentionally narrow. It covers hard bounces and complaints for transactional family invites and future non-auth notification emails. It is not a marketing preference center, and it does not change Cognito account-security email behavior.

## Current Behavior

- `EmailSuppressions` stores normalized recipient addresses suppressed for `HardBounce` or `Complaint`.
- Family invite outbox processing checks `EmailSuppressions` before sending email.
- Suppressed invite recipients do not receive invite email, and the outbox event is still marked processed so delivery retries do not loop.
- Registered suppressed recipients can still receive in-app alerts and push notifications for the invite.
- Brevo transactional webhooks are not wired here. SES hardening is the target of this change.

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

## Monitoring

To keep baseline cost low, this change does not add paid CloudWatch alarms by default. Monitor:

- SES account reputation and bounce/complaint metrics in the SES console or CloudWatch;
- EventBridge rule metrics for failed invocations;
- `/aws/lambda/conscia-outbox-processor` logs for `Suppressed email ... after SES ...` entries.

If SES volume grows, add CloudWatch alarms for SES bounce/complaint rate and EventBridge failed invocations.
