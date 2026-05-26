# Conscia Planned Follow-Ups

This file is the canonical follow-up list for the repo as of 2026-05-26. Everything here is intentionally not complete yet or still needs real-world validation after the audit pass.

## Immediate Follow-Ups

### Email and domain operations

- Fill `ICLOUD_INBOX_MX_RECORDS_JSON`, `ICLOUD_INBOX_TXT_RECORDS_JSON`, and `ICLOUD_INBOX_CNAME_RECORDS_JSON` with the exact record values Apple provides for the custom domain.
- Re-deploy `Conscia-Email` after those values are added and verify Route53, SES, and iCloud all show healthy status.
- If SES is still sandboxed, request production access and verify invite delivery with real recipient mailboxes.
- Decide whether the DMARC policy should stay at `p=quarantine` or move to a stricter production posture after mail delivery is stable.
- Add a real mailbox or workflow for DMARC aggregate reports if you extend the DMARC policy with `rua` or `ruf`.

### Infra and release hardening

- Replace the obsolete `DnsValidatedCertificate` usage in `infra/src/Conscia.Infra/WebStack.cs` with a proper modern certificate flow that still provisions the CloudFront viewer certificate in `us-east-1`; this likely needs a dedicated certificate stack or cross-region certificate handoff rather than a naive in-stack `Certificate` swap.
- Add CloudWatch alarms for recurring processor failures, outbox failures, and unusually high duration/error rates.
- Consider CI assertions around email-stack outputs so missing iCloud JSON values are surfaced earlier when inbox delivery is expected.

## Product and Platform Follow-Ups

### Recurring transactions

- Add a dedicated recurring-schedule management screen in the app.
- Replace the current due-schedule scan with a queryable access pattern such as `NextRunAt`.
- Add stronger conditional idempotency around generated occurrences.
- Add selective recurring reminder push delivery once the signal rules are settled.

### Receipts

- Track OCR confidence and correction patterns by merchant/category.
- Add more explicit cost and timeout guardrails around Textract and downstream parsing.

### Insights and coaching

- Weekly digest summaries that connect spending, emotion, and reflection.
- Richer regret-memory prioritization and alert ranking.
- Deeper merchant/category insight surfaces and longer-horizon trend framing.
- More expressive voice-first transaction and assistant entry.

### Shared and premium experiences

- Google Play RTDN support remains deferred.
- Browser/web push is still not wired; current push support is device-token registration plus backend delivery for mobile.
- Collaborative household planning can go further, but reimbursement/settlement flows are still intentionally out of scope.

### Web and positioning

- Keep evolving the marketing site so it stays aligned with the shipped product surfaces rather than drifting into aspirational-only messaging.
- Revisit roadmap copy after the next insight and memory milestones land.

## Audit Residual Risks

- The repo is now safer against placeholder Lambda deployments, but local `cdk synth` without published assets will intentionally fail unless `CONSCIA_ALLOW_PLACEHOLDER_ASSETS=true` is set.
- The infrastructure can create iCloud inbox DNS records, but it cannot invent the Apple-issued values. That remains a manual handoff from Apple’s setup UI.
- Old strategy/spec markdown files were removed during consolidation. If you need historical design rationale later, recover it from git history rather than recreating parallel docs.
