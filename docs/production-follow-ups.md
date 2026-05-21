# Production Follow-Ups

This is the short list of intentionally deferred production-hardening items that should stay visible after the MVP release path lands.

## Recurring Transactions

- Add a `NextRunAt` access pattern for recurring schedules. The current MVP processor scans the recurring schedule table for due items; before meaningful scale, add a DynamoDB GSI keyed for active schedules by due time so the processor can query due work instead of scanning.
- Add conditional idempotency around generated recurring occurrences. The processor checks for an existing `(RecurringScheduleId, RecurringOccurrenceDate)` before writing, but a conditional write or dedicated occurrence key would make concurrent retries safer.
- Add recurring schedule management UI. The API supports list, update, and delete; the app currently creates schedules from the transaction form and displays recurring provenance, but does not expose a full schedule-management screen.
- Add recurring processor alarms. The Lambda has one-month log retention through the observability stack; add CloudWatch alarms for repeated failures and unusually high duration once production traffic starts.
- Consider selective push notifications for high-signal recurring reminders. In-app alerts exist now; push should stay opt-in/high-value so recurring reminders do not become noise.

## Receipt Scanning

- Track receipt OCR quality by merchant/category confidence. The MVP parser fails closed when uncertain, but production should surface aggregate confidence and common correction patterns.
- Add provider-level timeout/cost guardrails for Textract and Bedrock. The service already uses bounded parsing, but alarms and dashboards should make spend and error rates visible.
