# Shared Conscia Family Space Design

**Date:** 2026-05-12
**Status:** Approved for MVP planning
**Feature:** Family sharing between registered Conscia users

## Goal

Add **Shared Conscia** as a premium-sponsored Family Space where registered household members can plan shared finances together without turning Conscia into a joint bank account, surveillance tool, or reimbursement ledger.

The MVP should help families answer:

> Are we making good household money decisions together?

It should not try to answer:

> Who owes whom?

## Product Principles

- Personal by default, Family only when explicitly chosen.
- Share household planning context, not private account ownership.
- Keep privacy visible everywhere a shared record appears.
- Keep roles simple and understandable.
- Make Family advice explicit. No silent AI context mixing.
- Avoid features that create unnecessary household tension.
- Premium sponsors the Family Space, but invited members can participate without their own Premium subscription.

## MVP Shape

Use the **Shared Household Space** model.

Each user keeps their own Personal Conscia account. A Premium user can create one Family Space, invite other registered or future registered users by email, and share selected household records.

Supported shared record types:

- Family expenses
- Family budgets
- Family recurring schedules
- Family-mode AI/pre-purchase context
- Family-related Journey quests and achievements

Out of scope for MVP:

- Multiple Family Spaces per user
- Full family wallet controls
- Child/parent approval flows
- Payment requests
- Reimbursement tracking
- Settlement calculations
- Bulk import of existing personal records
- Shared Premium entitlement for every member
- Anonymous or guest members
- Silent import of existing personal history

## Entitlement Model

Family Space is a Premium feature, but Premium is checked only for the Family Space owner/creator in MVP.

Rules:

- Only a Premium user can create a Family Space.
- Invited users can participate for free according to their role.
- Joining a Family Space does not grant Premium to the invited user.
- Premium/free checks for other app features remain per user.
- Apple/Google app-store Family Sharing is separate from Conscia Family Space and must not be assumed.
- If the owner loses Premium, the Family Space becomes read-only after a 14-day grace period.

Product boundary:

> Family Space shares household planning. Family Plan would share Premium entitlement. MVP includes Family Space only.

## Membership Rules

Each user can belong to zero or one Family Space.

Rules:

- A user cannot create a Family Space if they already belong to one.
- A user cannot accept an invite if they already belong to another Family Space.
- Every Family Space must always have at least one Owner.
- If the only Owner wants to leave, they must transfer ownership first or delete the Family Space.
- Invites are sent by email and are bound to the invited email address.
- An authenticated user can only accept an invite if their verified account email matches the invited email.

## Roles

Use three roles:

- **Owner**
- **Contributor**
- **Viewer**

### Owner

Owner can:

- Rename the Family Space.
- Invite members.
- Remove members.
- Change member roles.
- Transfer ownership.
- Delete the Family Space.
- Create, edit, and delete any shared household record.

### Contributor

Contributor can:

- View Family Space records and insights.
- Add shared expenses.
- Add shared budgets.
- Add shared recurring schedules.
- Edit or delete shared records they created.

Contributor cannot:

- Invite or remove members.
- Change roles.
- Edit or delete records created by others.
- Delete the Family Space.

### Viewer

Viewer can:

- View Family Space records and insights.
- Accept family-related Journey events that are based on view/review actions.

Viewer cannot:

- Add shared records.
- Edit or delete shared records.
- Manage members.

## Sharing Model

Records remain personal unless explicitly marked as Family.

For a shared transaction:

- `UserId` remains the creator/owner of the record.
- `FamilySpaceId` is set.
- `Visibility` or equivalent scope becomes `Family`.
- `SharedAt` records when it was shared.
- `SharedByUserId` records who shared it.

Behavior:

- Creator still sees the record in Personal timeline with a Family badge.
- Family Space shows the record to all members.
- Other members do not see the record in their Personal timeline.
- Personal totals include the creator's own family-shared records.
- Family totals include all family-shared records once.

This avoids duplicate records, disappearing personal history, and double counting.

## Income Privacy

MVP should avoid exact salary disclosure by default.

Rules:

- Actual salary can stay private in Personal.
- Family Space should not require users to publish salary or contribution schedules.
- Family cashflow should start from explicitly marked Family transactions and Family budgets only.
- Exact income sharing can be considered later as a separate, opt-in design.

## Expenses

Shared expenses represent household spending, not reimbursement claims.

Examples:

- `Groceries -₱4,000 · Added by Arvie · Family`
- `Internet -₱1,899 · Added by Mariel · Family`
- `School supplies -₱2,400 · Added by Arvie · Family`

Rules:

- Contributor can add shared expenses.
- Shared expenses power family budgets, family trends, family insights, and Family-mode AI.
- Every shared expense displays who added it.
- No expense should automatically become Family based on category or counterparty.

## Budgets

Family budgets track household category spending.

Rules:

- Budget scope can be Personal or Family.
- Family budgets count Family transactions only.
- Personal budgets count the current user's personal spending according to existing personal budget rules.
- A category can have a Personal budget and a Family budget independently.
- Budget trend cards should make the active scope clear.

Example:

> Family Dining Budget: ₱7,400 / ₱9,000 used · Added by Mariel

## Recurring Schedules

Recurring schedules can be Personal or Family.

Family recurring schedules include:

- Rent
- Utilities
- Internet
- Insurance
- School fees
- Shared subscriptions

Rules:

- Generated transactions inherit the schedule scope.
- Family schedule occurrences appear in Family Space.
- Family schedules power family forecasts, cashflow, reminders, and Family-mode AI.
- Contributor can edit/delete schedules they created.
- Owner can edit/delete all Family schedules.

## Existing Personal Records

MVP does not include bulk import.

Existing personal records stay personal unless the user edits an individual supported record and explicitly changes its scope to Family.

Rules:

- Do not provide a bulk import screen.
- Do not import personal budgets into Family Space.
- Do not import recurring schedules in bulk.
- Do not duplicate records into Family Space.
- Keep attribution visible on any individual record that is explicitly shared later.

Reason:

Bulk import creates confusing edge cases around budget ownership, recurring schedules, insights, double counting, and privacy. Family Space should start clean and grow from intentionally-created shared records.

## No Settlement Rule

MVP must explicitly avoid settlement.

Do not implement:

- Who owes whom
- Reimbursement balances
- Paid/unpaid settlement status
- Payment requests
- Split calculations
- Push notifications saying one member owes another
- Insights comparing whether one member contributed enough

Reason:

Settlement can create unnecessary household tension and changes the emotional tone from financial coaching to interpersonal accounting.

Allowed:

- Shared cashflow summaries.
- Household budget health.
- Upcoming shared obligations.
- Positive, non-comparative insights such as:

> Your household has covered this month's recurring essentials.

Disallowed:

> Arvie is carrying more than Mariel.

## AI And Pre-Purchase Context

Family AI context must be explicit.

Pre-purchase assistant and relevant AI surfaces should have a clear context:

- Personal advice
- Family advice

Personal advice uses:

- User's personal records.
- User's own family-shared records where relevant.
- Personal budgets.
- Personal insights.

Family advice uses:

- Family budgets.
- Family expenses.
- Family recurring schedules.
- Family trends.
- Shared insights.

Rules:

- Family advice is available only to Family Space members.
- The active context must be obvious before the AI response.
- AI must not silently mix another member's family data into Personal mode.

## Conscience Journey

Journey remains individual.

Family actions can create individual Journey events, quests, badges, and achievements.

Examples:

- Invite a family member.
- Accept a Family Space invite.
- Add a family expense.
- Create a shared recurring schedule.
- Review a family budget trend.
- Check with Conscia before a family purchase.

Rules:

- XP goes to the acting user.
- No shared family level in MVP.
- No automatic XP for members who did not take the action.
- Quest progress can appear in-app/bell only unless it is a major Journey moment like level-up.

## Invites And Notifications

Invite source of truth is the backend pending invite.

Invite flow:

- Owner invites by email.
- If the email belongs to an existing user, create an in-app notification and show it in the bell.
- If device push delivery is configured and active device tokens exist, send a device push.
- If the email does not belong to a user yet, create a pending invite.
- When that email registers and verifies/signs in, show the pending invite.
- Invites expire after 14 days.

Notification policy:

- Family invites are high-signal and should go to the bell.
- Family invites should also go to device push once server-side FCM sending is implemented.
- Family invite push is likely the first transactional user-to-user push type.
- Quest progress should not become device push.

Current implementation reality:

- The app can register FCM device tokens when push is enabled.
- Backend server-side FCM sending is still needed before real device push delivery works.
- Until FCM sending exists, invites should still appear as in-app/bell notifications.

## Dashboard And Navigation

If the user does not belong to a Family Space:

- App behaves as it does today.
- Premium users see a Family Space entry point in Settings or a subtle Dashboard card.
- Free users can see Family Space as a Premium feature but cannot create one.

If the user belongs to a Family Space:

- Dashboard can show a Personal / Family context switcher or scoped cards.
- Family summary should use mascot-led detail and clear labels.
- Transactions can filter by Personal / Family.
- Budgets can filter by Personal / Family.
- Recurring schedules can filter by Personal / Family.
- Assistant/pre-purchase can choose Personal / Family advice.

The context selector must not be cute at the expense of clarity.

## Data Model Sketch

Entities to add:

- `FamilySpace`
- `FamilyMember`
- `FamilyInvite`

Fields to add to shared-capable records:

- `FamilySpaceId`
- `Visibility` or `Scope`
- `SharedAt`
- `SharedByUserId`

Sketch:

```csharp
public class FamilySpace
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string CurrencyCode { get; set; } = "USD";
    public Guid CreatedByUserId { get; set; }
    public DateTime CreatedAt { get; set; }
    public bool IsReadOnly { get; set; }
}

public class FamilyMember
{
    public Guid Id { get; set; }
    public Guid FamilySpaceId { get; set; }
    public Guid UserId { get; set; }
    public FamilyMemberRole Role { get; set; }
    public DateTime JoinedAt { get; set; }
}

public class FamilyInvite
{
    public Guid Id { get; set; }
    public Guid FamilySpaceId { get; set; }
    public string Email { get; set; } = string.Empty;
    public FamilyMemberRole Role { get; set; }
    public Guid InvitedByUserId { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? AcceptedAt { get; set; }
    public DateTime? DeclinedAt { get; set; }
}

public enum FamilyMemberRole
{
    Owner,
    Contributor,
    Viewer
}
```

Constraints:

- Unique active membership per user.
- Unique pending invite per family/email.
- At least one Owner per Family Space.
- Invited email must be normalized.

## Infrastructure Cost Insights

Shared Conscia should reuse the existing serverless architecture and avoid adding always-on infrastructure for MVP.

### Expected incremental infrastructure

New storage:

- Relational tables for `FamilySpace`, `FamilyMember`, and `FamilyInvite`.
- Added scope/family fields on shared-capable records.
- In-app invite notifications using the existing alerts table/pattern.
- Existing device-token table for push recipients.

New compute:

- Additional API endpoints for family space management.
- Additional authorization checks on existing transaction, budget, recurring, insight, and AI endpoints.
- Optional server-side FCM sender when push delivery is implemented.
- CDK-managed Outbox Lambda updates for any async family events that should not run inline with the API request.

No new MVP infrastructure should be required for:

- Redis
- ECS
- Always-on workers
- WebSockets
- Separate notification service
- Separate family-ledger service
- Event-driven settlement processor

### Outbox Lambda infrastructure-as-code

Async family workflows should use the existing CDK outbox infrastructure rather than a hosted background service.

Existing baseline:

- `infra/src/Conscia.Infra/OutboxStack.cs` defines `conscia-outbox-processor` as a .NET 8 ARM64 Lambda.
- The Lambda is deployed from the outbox publish asset.
- It runs inside the VPC with RDS connectivity.
- It has read/write access to the `OutboxEvents` table.
- It is already covered by infra tests in `infra/tests/Conscia.Infra.Tests/StackTests.cs`.

Shared Conscia should extend this path for async work such as:

- Sending family invite push notifications after the invite is persisted.
- Generating family-related Journey events after shared actions.
- Updating future family summary/projection records if we add cached family dashboards.
- Running retryable side effects that should not block the user-facing API response.

Rules:

- Do not add another always-on `BackgroundService` for production family processing.
- Do not add a second outbox processor stack unless there is a measured isolation need.
- Add new outbox event types for family workflows and process them in the Lambda.
- Keep API writes atomic with outbox event creation where possible.
- Keep outbox side effects idempotent because Lambda retries can replay records.
- Add/update CDK tests whenever the Outbox Lambda permissions, event sources, environment variables, or assets change.

### Cost posture

The MVP should be low incremental cost because it mostly adds small metadata rows and extra reads/writes around actions users already take.

Cost drivers to watch:

- Family dashboard fan-out queries if every screen reads many member records separately.
- Family-mode AI calls if we add too much household context or trigger them automatically.
- Push notification delivery loops if they query device tokens one user at a time without batching.
- Extra DynamoDB global secondary indexes if every new access pattern becomes its own index.

Cost controls:

- Keep Family Space limited to one space per user for MVP.
- Keep dashboard family summaries compact and paginated/drill-down for detail.
- Use existing alert/device-token infrastructure before adding new queues or workers.
- Use the existing CDK-managed Outbox Lambda for retryable async side effects instead of API inline work or an always-on worker.
- Do not add settlement; it would create more writes, more history, more notifications, and more support surface.
- Track simple metrics: family spaces created, active members, family records shared, family AI calls, invite notifications sent.

### Push delivery cost note

Firebase Cloud Messaging itself is currently a no-cost Firebase product, but sending pushes still requires backend work and some AWS usage.

MVP behavior:

- Bell/in-app invite notification is required.
- Device push is best effort once FCM sending exists.
- Do not create a dedicated always-on push service for invites.
- Prefer sending push from the API or an existing background path unless volume proves otherwise.

### AI cost note

Family-mode pre-purchase advice can become the most expensive part if used casually.

Rules:

- Only call AI when the user explicitly asks for Family advice.
- Build compact family context summaries server-side.
- Do not send full family transaction history to the model.
- Reuse existing insights/budget/cashflow summaries where possible.

### Release cost checklist

Before implementation ships:

- Estimate request/read/write volume using AWS Pricing Calculator.
- Add CloudWatch metrics or structured logs for family endpoint request count.
- Add a dashboard or saved Cost Explorer view filtered to the API, DynamoDB tables, Lambda functions, and FCM sender path.
- Set budget alerts for unexpected DynamoDB read/write growth.
- Document whether FCM sending is enabled or in-app-only for the release.

## API Surface Sketch

Suggested endpoints:

- `GET /api/v1/family-space`
- `POST /api/v1/family-space`
- `PATCH /api/v1/family-space`
- `DELETE /api/v1/family-space`
- `GET /api/v1/family-space/members`
- `POST /api/v1/family-space/invites`
- `POST /api/v1/family-space/invites/{id}/accept`
- `POST /api/v1/family-space/invites/{id}/decline`
- `PATCH /api/v1/family-space/members/{id}/role`
- `DELETE /api/v1/family-space/members/{id}`

Existing list endpoints should get an explicit scope filter where appropriate:

- `scope=personal`
- `scope=family`
- `scope=all`

## Error Handling

Important errors:

- Free user tries to create Family Space.
- User already belongs to a Family Space.
- Invitee already belongs to a Family Space.
- Invite expired.
- Invite email does not match authenticated user.
- Last Owner tries to leave.
- Contributor edits another member's record.
- Viewer tries to mutate shared records.
- Owner's Premium has lapsed and Family Space is read-only.

Use user-friendly messages. Avoid exposing internal authorization terms in UI copy.

## Testing Strategy

Backend tests:

- Premium user can create Family Space.
- Free user cannot create Family Space.
- Invited free user can accept and participate.
- User cannot join more than one Family Space.
- Last Owner cannot leave without transfer/delete.
- Contributor can edit own shared records but not others.
- Viewer cannot create or edit shared records.
- Family queries only return records from the caller's Family Space.
- Personal queries do not expose other members' records.
- Family invite creates in-app notification.

Flutter tests:

- Family Space setup flow.
- Invite flow.
- Pending invite notification card.
- Personal/Family context toggle.
- Family badges on shared records.
- Family-mode pre-purchase context.

Manual QA:

- Existing user invite.
- Future user pending invite after registration.
- Owner Premium lapse read-only behavior.
- Story-demo seed with two household members.
- No settlement or reimbursement language appears anywhere.

## Seed And Demo Requirements

Add a Shared Conscia story-demo household later:

- Premium owner account.
- Contributor spouse account.
- Optional Viewer account.
- Shared family budget.
- Shared recurring utility/subscription.
- Manually-created family transaction with Family badge.
- Pending invite.
- Family invite bell notification.
- Family-related Journey quest.
- Family-mode pre-purchase example.

## MVP Implementation Decisions

- Shared-capable records should have both `FamilySpaceId` and an explicit `Scope` enum. `FamilySpaceId` connects the record to the household; `Scope` keeps UI and authorization code readable.
- Owner Premium lapse uses a 14-day grace period. After that, Family Space is read-only until the owner renews Premium or transfers ownership to another Premium member.
- Navigation entry points should be Settings as the durable management home, plus a subtle Dashboard card for Premium users who have not created a Family Space yet.
