# Location-Aware Assistance Design

## Summary

Add a shared, privacy-forward location assistance system that can improve both transaction entry and pre-purchase coaching. The app should prompt the user the first time they open Add Transaction or Pre-Purchase Assistant, explain the benefit clearly, and store the decision so we do not keep asking after a deny. Users can always change the behavior later in Settings.

This feature also adds a lightweight budget nudge: after saving an expense in a category with no matching budget, Conscia should create an in-app alert encouraging the user to add a budget for that category.

## Goals

- Make merchant and category entry easier in Add Transaction.
- Make Pre-Purchase Assistant feel more guided and less blank-state heavy.
- Keep location usage transparent and easy to disable later.
- Avoid modal nagging for budget setup; use in-app alerts instead.
- Reuse one shared preference and one shared suggestion pipeline across both surfaces.

## Non-Goals

- Automatic transaction creation or silent category reassignment.
- Background location tracking.
- Geofencing or persistent place history UI.
- Mandatory location access for any feature.
- Budget nudges for income transactions.

## Product Decisions

### Permission and Preference Model

- The app prompts the first time the user opens either Add Transaction or Pre-Purchase Assistant.
- The first prompt is an in-app explainer before the OS permission request.
- If the user declines in the in-app explainer, we mark the feature as prompted and do not ask again automatically.
- If the user accepts the explainer but denies OS permission, we also stop automatic prompting.
- In both decline cases, the copy should explicitly say the behavior can be changed later in Settings.
- Settings becomes the long-term control point for enabling or disabling location-aware suggestions.

### Location-Aware Suggestions

- When enabled and permitted, Add Transaction can use the current location to suggest nearby merchants and likely categories.
- When enabled and permitted, Pre-Purchase Assistant can use the current location to suggest a merchant and category faster before the AI request is submitted.
- Suggestions are assistive only. Users remain in control of the final merchant and category values.
- If location is unavailable, denied, or slow, both screens continue to work normally with manual entry.

### Budget Nudge Rule

- Only trigger after saving an expense.
- Only trigger if the expense category has no matching budget allocation.
- Deliver the nudge as an in-app alert, not a blocking modal.
- The alert should include a direct path into the budget-management flow.

## User Experience

### First-Use Prompt Flow

The first time the user enters Add Transaction or Pre-Purchase Assistant, show a compact explainer surface:

- Title: `Use your location for smarter suggestions?`
- Value proposition: nearby merchant suggestions and likely category suggestions
- Privacy framing: location is only used to improve suggestions while using the feature
- Actions:
  - `Not now`
  - `Enable`
- Helper note: `You can change this later in Settings.`

If the user taps `Enable`, request OS location permission immediately. If granted, enable the feature. If denied, keep the feature disabled and surface a short confirmation that it can be enabled later in Settings.

### Add Transaction

Add Transaction should stop hiding location value behind an advanced-feeling switch. Instead:

- Keep the merchant and category inputs visible and editable.
- Show a small suggestion row or card near those inputs when location assistance is active.
- Suggest nearby merchant names first.
- Suggest likely categories based on user history at the same or nearby merchant/place.
- Preserve manual editing as the primary source of truth.

The old `Include Location` switch in More Options should be retired or absorbed into the global assistance model so the screen does not have two overlapping location concepts.

### Pre-Purchase Assistant

Pre-Purchase Assistant is a strong reuse target because the current form has a higher cognitive load:

- A user must currently know the item, amount, currency, and category before the assistant helps.
- With location assistance enabled, the screen can pre-suggest nearby merchants and a likely category.
- This should make the screen feel more guided and reduce blank-form anxiety.

This does not redesign the whole pre-purchase experience yet, but it creates a clear path for a later usability pass.

### Settings

Add a settings control such as:

- `Smart location suggestions`
- Subtitle: `Use your current location to suggest merchants and categories`

If the user previously denied OS permission, the settings screen should explain that system permission may also need to be enabled.

## Data Model

### New User Preference Fields

Add shared preference or persisted user-preference fields for:

- `locationSuggestionsEnabled`
- `locationSuggestionsPrompted`

These should live in the same preference domain as currency/locale-style user preferences unless there is already a stronger pattern for feature toggles in the app.

If the team prefers server-backed cross-device persistence for this preference, the same field names can be added to the profile model later. For the first implementation, local preference storage is acceptable as long as Settings and both feature screens use the same source of truth.

## Technical Design

### Shared Services

Add a small location-assistance layer that owns:

- reading the stored preference flags
- deciding whether a first-use prompt is needed
- requesting OS permission
- retrieving current location on demand
- producing merchant/category suggestions

This should be separate from screen widgets so Add Transaction and Pre-Purchase Assistant can reuse it without duplicating permission logic.

### Suggestion Strategy

The suggestion pipeline should be layered:

1. Check whether the feature is enabled and permitted.
2. Request current location on-demand for the active screen.
3. Resolve nearby merchant candidates.
4. Combine those candidates with transaction history to infer likely categories.
5. Return a ranked suggestion set to the UI.

The first implementation can start with a simple heuristic:

- nearby merchant suggestion based on available place lookup or stored transaction metadata
- category suggestion based on the user’s recent transactions for the same merchant or a normalized merchant name

The system should degrade gracefully if merchant lookup is unavailable by still using any available historical merchant-category mapping.

### Budget Nudge Integration

After a transaction save succeeds:

1. Confirm the transaction is an expense.
2. Check whether there is a matching budget for the selected category.
3. If no budget exists, create an in-app alert payload for the existing alerts system.

The alert should be lightweight and deduplicated enough that repeated spending in the same unbudgeted category does not flood the user.

## Error Handling

- If the permission request fails, keep the form usable and show a non-blocking message.
- If location lookup times out, skip suggestions rather than blocking submission.
- If merchant lookup fails, continue with category suggestions when possible.
- If both suggestion sources fail, fall back to the existing manual experience.
- If budget alert creation fails, transaction save still succeeds.

## Testing Strategy

### Unit Tests

- location preference state transitions
- first-use prompt gating logic
- denied-permission behavior
- suggestion ranking from location + history inputs
- budget-nudge trigger conditions

### Widget Tests

- Add Transaction shows the first-use prompt only once
- Pre-Purchase Assistant shows the same first-use prompt only once
- Settings toggle reflects stored preference
- expense without budget produces an in-app alert
- income does not produce a budget nudge

### Integration / End-to-End Checks

- enable from Add Transaction, then verify Pre-Purchase Assistant uses the same setting
- deny once, verify no repeated auto-prompt on reopen
- toggle on again from Settings and verify suggestions resume

## Documentation Impact

Update these docs during implementation:

- `docs/README.md`
  - refresh stale overall status text
  - keep the phase table but align the surrounding progress summary with current reality
- any onboarding or transaction-flow docs that currently imply location is only a hidden advanced option

## Rollout Notes

- This should be safe to ship incrementally.
- The first release can keep suggestions simple as long as the prompt flow and settings control are correct.
- More advanced merchant intelligence can be layered in later without changing the permission model.

## Open Questions Resolved

- Default behavior: prompt first use in Add Transaction and Pre-Purchase Assistant
- Decline behavior: do not auto-prompt again; remind the user they can change it in Settings
- Budget nudge scope: expense only, category without matching budget only
- Delivery channel: in-app alerts
