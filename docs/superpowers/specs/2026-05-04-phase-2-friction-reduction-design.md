# Phase 2: Friction Reduction — Design Spec

**Date:** 2026-05-04
**Branch:** feature/phase-2-friction-reduction

## Goal

Reduce the time and effort to log a transaction on the pre-purchase screen by adding quick preset chips, voice input with client-side parsing, smart one-tap purchase suggestions derived from transaction history, and a SpeedDial FAB exposing three entry points.

---

## Architecture Overview

### New Flutter files
| File | Responsibility |
|------|---------------|
| `app/lib/screens/transactions/widgets/quick_preset_chips.dart` | Horizontal chip row — dynamic or static fallback |
| `app/lib/screens/transactions/widgets/purchase_suggestion_chips.dart` | "Your usual" suggestion rows above preset chips |
| `app/lib/screens/transactions/widgets/voice_input_button.dart` | Mic icon suffix for the description field |
| `app/lib/utils/utterance_parser.dart` | Pure-Dart parser: amount + category extraction from transcript |
| `app/lib/providers/category_frequency_provider.dart` | Derived provider — top-5 categories from transaction history |
| `app/lib/providers/purchase_suggestions_provider.dart` | FutureProvider — fetches from `/api/v1/suggestions/purchases` |
| `app/lib/widgets/speed_dial_fab.dart` | SpeedDial FAB with three child actions |

### Modified Flutter files
| File | Change |
|------|--------|
| `app/lib/screens/transactions/transaction_form_screen.dart` | Add preset chips, suggestion chips, voice button |
| `app/lib/screens/main_scaffold.dart` (or equivalent) | Replace FloatingActionButton with SpeedDialFab |
| `app/pubspec.yaml` | Add `speech_to_text`, `flutter_speed_dial` |

### New backend files
| File | Responsibility |
|------|---------------|
| `src/Conscia.Application/Interfaces/IPurchaseSuggestionService.cs` | Service contract |
| `src/Conscia.Application/DTOs/PurchaseSuggestionDto.cs` | Response shape |
| `src/Conscia.Application/Services/PurchaseSuggestionService.cs` | Query + rank logic |
| `src/Conscia.Api/Endpoints/SuggestionEndpoints.cs` | `GET /api/v1/suggestions/purchases` |
| `src/Conscia.Api/Endpoints/UtteranceEndpoints.cs` | `POST /api/v1/transactions/parse-utterance` (premium gate) |
| `tests/.../Application/PurchaseSuggestionServiceTests.cs` | Unit tests |
| `tests/.../Api/SuggestionEndpointTests.cs` | Endpoint tests |

---

## Section 1: Quick Preset Chips

### Behavior
A horizontally scrollable chip row sits above the description field on the transaction form. Tapping a chip:
1. Pre-fills the category dropdown to the chip's category.
2. Focuses the description field (keyboard opens).
3. Highlights the chip with a purple border until the user taps another chip or clears the field.
4. Does **not** touch the amount field.

### Data source — `categoryFrequencyProvider`
- Derived from the existing `transactionListProvider` with no new API call.
- Groups transactions by category, sorts descending by count, takes top 5.
- Falls back to the static list `[Coffee, Dining, Shopping, Gaming, Travel]` when fewer than 5 distinct categories exist in the transaction list.
- The transition from static to dynamic happens automatically as soon as the 5th distinct category appears.

---

## Section 2: Voice Input + Utterance Parser

### UI
A microphone icon (`🎙️`) sits as a suffix inside the description `TextField`. Tapping it:
1. Requests microphone permission via `speech_to_text`. If denied, the icon is hidden permanently for the session — no crash, no error dialog.
2. Shows a red "Listening…" state with a pulsing indicator.
3. Stops on silence or a second tap, fires the transcript to `UtteranceParser`.

### `UtteranceParser` (pure Dart, no network)
Three extraction steps in order:

**Amount**
- Regex: `\$?\d+(\.\d{1,2})?` — matches `5.50`, `$5.50`
- Number-word dictionary: `{five: 5, fifty: 0.50, twenty: 20, …}` — handles spoken amounts like "five fifty" → 5.50
- First match wins; tokens consumed from transcript.

**Category**
- Keyword map: e.g. `{coffee, latte, starbucks, espresso} → Coffee`, `{lunch, dinner, restaurant, jollibee} → Dining`, etc.
- First keyword match wins; tokens consumed.

**Description**
- Remainder of transcript after stripping amount tokens and matched category keywords.
- Falls back to the raw transcript if stripping produces an empty string.

### Parse outcomes
| Outcome | Amount found | Category found | UI response |
|---------|-------------|----------------|-------------|
| Full success | ✓ | ✓ | All three fields filled, green confirmation banner |
| Partial — no amount | ✗ | ✓ | Description + category filled, yellow warning, amount field focused |
| Partial — no category | ✓ | ✗ | Description + amount filled, category dropdown focused |
| Low confidence | ✗ | ✗ | Raw transcript in description, yellow warning |

### Premium AI fallback
- Only shown when **both** amount and category fail to parse.
- Free users: yellow warning with manual-fill prompt.
- Premium users: yellow warning + "Try AI parse" button that calls `POST /api/v1/transactions/parse-utterance`.
- The endpoint calls Claude (Haiku for cost) with the transcript and returns `{ description, amount, category }`.
- Gate enforced server-side via subscription check.

---

## Section 3: Smart Purchase Suggestions

### Threshold
The "Your usual" section is completely hidden when the user has fewer than 10 total transactions. The gate is enforced server-side: `GET /api/v1/suggestions/purchases` returns an empty list when below threshold. Flutter hides the section when the list is empty.

### Backend — `PurchaseSuggestionService`
**Query:** Last 90 days of transactions for the user, grouped by `description` (case-insensitive trim). Groups with fewer than 2 occurrences are excluded.

**Ranking:** `score = count × recencyWeight`, where `recencyWeight` decays linearly from 1.0 (today) to 0.1 (90 days ago) based on the most recent transaction in the group.

**Amount:** Median of the group's amounts — robust to occasional price variation.

**FrequencyLabel:** Human-readable string computed server-side:
- If any transaction in the group is within the last 7 days → `"N× this week"`
- Otherwise → `"N× this month"`

**Response:** Top 5 as `PurchaseSuggestionDto`:
```csharp
record PurchaseSuggestionDto(
    string Description,
    decimal Amount,
    string CurrencyCode,
    string Category,
    string FrequencyLabel
);
```

### Endpoint
`GET /api/v1/suggestions/purchases` — auth-required, standard rate limiting. No query parameters.

### Flutter — `purchaseSuggestionsProvider`
- `FutureProvider<List<PurchaseSuggestionDto>>` — fetches on form open.
- Invalidated when `transactionListProvider` changes (so a new transaction immediately updates suggestions next time the form opens).
- No client-side caching — always fresh.

### UI
- "Your usual" section appears **above** the preset chips row when suggestions list is non-empty.
- Each suggestion is a full-width tappable row: `[icon] Description · · · $Amount · FrequencyLabel`
- Tapping fills description, amount, and category — same as one-tap submit minus the submit itself.

---

## Section 4: FAB SpeedDial Redesign

### Three child actions
| Icon | Label | Action |
|------|-------|--------|
| 💸 | Add Expense | Navigate to `AppRoutes.addTransaction` (existing form) |
| ✨ | Ask Conscia | Navigate to `AppRoutes.chat`; snackbar "Coming soon" if route doesn't exist |
| 📷 | Scan Receipt | Snackbar "Coming in a future update" — deferred, icon included for final layout |

### Implementation
- Package: `flutter_speed_dial`.
- Replace the existing `FloatingActionButton` in the main scaffold with `SpeedDial`.
- Dim overlay on open; tapping overlay closes the dial.
- Child FABs animate up with staggered delay (handled by `flutter_speed_dial` defaults).
- No routing changes; no layout shifts (bottom nav already reserves FAB space).

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| Microphone permission denied | Icon hidden for session; no error dialog |
| `speech_to_text` unavailable (no engine) | Same as permission denied |
| Suggestions API fails | `purchaseSuggestionsProvider` returns error state; Flutter hides "Your usual" section silently |
| AI parse API fails (premium) | Snackbar "Couldn't parse — please fill manually"; fields left as-is |
| `speech_to_text` returns empty transcript | Yellow warning "Couldn't hear anything — try again"; fields unchanged |

---

## Testing

### Unit tests (backend)
- `PurchaseSuggestionService` — threshold gate (0, 9, 10 transactions), ranking order, median amount, frequency label logic
- `UtteranceEndpoints` — premium gate (403 for free user), valid parse response, malformed body

### Unit tests (Flutter)
- `UtteranceParser` — numeric amounts, spoken amounts, category keywords, partial parse, empty transcript
- `categoryFrequencyProvider` — dynamic top-5, static fallback trigger, tie-breaking

### Widget tests
- `QuickPresetChips` — renders dynamic list, renders static fallback, tap fills category
- `PurchaseSuggestionChips` — hidden below threshold, renders rows, tap fills all three fields
- `VoiceInputButton` — idle state, listening state, parse success fills fields

---

## Out of Scope (Phase 2)

- Scan Receipt implementation (icon present, snackbar only)
- Income preset chips (expense-only for Phase 2)
- Offline voice recognition
- Multi-language utterance parsing
