# Transaction Screens SE Design

**Date:** 2026-05-13
**Status:** Approved for planning
**Feature:** Transactions list, add transaction, and edit transaction refinement for iPhone SE

## Goal

Bring the core transaction screens back into alignment with the approved Conscia iOS-forward v2 design language on iPhone SE without inventing new product behavior.

This pass is intentionally narrow. It is about:

- visual hierarchy
- spacing rhythm
- input treatment
- consistency between add and edit flows
- updating obsolete tests to match the approved UI

It is not about adding new transaction capabilities, changing business rules, or redesigning unrelated screens.

## Product Guardrails

- Respect the existing Conscia color, typography, radius, and spacing tokens exactly.
- Keep the app on the warm `paper` canvas, not pure white.
- Keep the floating dock nav behavior already approved; this spec does not redesign navigation.
- Keep transaction product behavior unchanged unless a UI requirement forces a tiny interaction fix.
- Do not invent new scopes, tags, or transaction states.
- Do not replace mascot sprites or introduce new illustration systems.

## Screens In Scope

- Transactions list
- Add transaction
- Edit transaction

## Screens Out Of Scope

- Transaction detail
- Receipt review / scanner
- Budgets and category management flows beyond what the transaction form already consumes
- Backend schema changes
- New filter logic or new transaction metadata

## Approved Direction

### 1. Transactions List

The transactions list should stay visually light and scroll efficiently on iPhone SE.

Approved structure:

- centered `Transactions` title
- trailing `+` action in the top bar
- one horizontal chip rail directly under the app bar
- date-grouped transaction rows below the chip rail
- floating dock nav at the bottom

Explicitly rejected for this screen:

- bringing back a separate `Personal / Family` segmented control
- wrapping every transaction row in its own heavy card
- adding large editorial blocks to the top of the list

#### List Layout

- Screen padding: `20px` horizontal
- Chip rail to first date header: `16px`
- Date header to first row: `10px`
- Gap between date groups: `18px`
- Target row height: `64px` to `68px`

#### Date Headers

Date headers should use the compact section-label treatment:

- uppercase text like `SUN, MAY 10`
- `microLabel` scale
- `mutedInk` color
- visually secondary to row content

#### Transaction Rows

Each row should read in three vertical bands:

- left: category badge tile
- center: merchant/title on line one, category or supporting label on line two
- right: amount on line one, compact icon-only tags on line two

Rules:

- merchant/title uses strong body emphasis
- supporting line uses `mutedInk`
- amount uses `amountList`
- expense amounts use `expense`
- income amounts use `income`
- tags stay icon-only and compact
- row separators should be subtle and only appear when they help grouping clarity

#### Filters

The top filter rail should remain chip-only for SE.

Rules:

- first chip is `All`
- category chips follow in a single horizontal row
- horizontal scrolling is acceptable
- chip density should not force a second line on SE

### 2. Add Transaction

The add transaction screen should return to full v2 form language. The current direction is cleaner than older builds, but some controls drifted back to generic inputs.

Approved field order:

1. `Expense / Income` segmented control
2. `AMOUNT`
3. amount hero field
4. `SCOPE`
5. `Personal / Family` segmented control
6. `CATEGORY`
7. horizontal category rail
8. `DETAILS`
9. merchant/source floating-label field
10. date floating-label field
11. divider
12. `RECURRING`
13. full-width CTA

#### App Bar

- leading iOS chevron
- centered title `Add transaction`
- no extra top-right action

#### Section Rhythm

- major section gap: `18px`
- label to control: `8px`
- maintain a compact but breathable vertical rhythm that fits fully on iPhone SE without feeling cramped

#### Segmented Controls

Both segmented controls should share the same visual system:

- pill track
- selected segment on white / paper surface
- unselected state in softened neutral/navy tint
- no check icons
- strong text contrast for the selected state

#### Amount Hero

The amount field remains a hero input, not a regular text field.

Rules:

- amount retains visual dominance near the top of the form
- currency selector can remain inline on the leading side
- empty state should stay visually clear without placeholder clutter
- spacing around the hero field must not collapse into adjacent sections

#### Scope

`SCOPE` must be visibly labeled. The segmented control should never appear detached from context.

Rules:

- show the scope section even when it only contains the binary personal/family choice
- reuse the same segmented style as the expense/income control

#### Category

The category selector stays a horizontal rail on SE.

Rules:

- keep it single-row and horizontally scrollable
- selected category should feel stronger, but still light enough to fit the iOS-forward tone
- do not duplicate the category name in adjacent labels or helper text

#### Details Inputs

This is the main corrective part of the redesign.

Rules:

- `Merchant (optional)` for expense and `Source (optional)` for income must use the Conscia v2 floating-label input treatment
- `Date` must also use the same floating-label filled-field treatment
- `Date` may include a trailing calendar icon
- idle fields use frosted fill with subtle border
- focused state uses `deepNavy`
- filled state keeps the label raised

Generic Material text fields or bare `InputDecorator` styling are not approved for these controls.

#### Recurring Section

Recurring should remain compact on SE.

Rules:

- section label uses the same compact uppercase treatment as other section labels
- helper copy stays directly under the label or title row
- switch is right-aligned
- additional recurrence controls stay hidden until recurring is enabled
- expanded recurring controls should still feel like part of the same form, not a separate card

#### CTA

The submit action should use the standard form CTA treatment:

- full width
- `48px` height
- pill radius
- strongest visual weight on the screen
- disabled state remains readable but subdued

### 3. Edit Transaction

Edit transaction should be structurally identical to add transaction.

Allowed differences:

- title becomes `Edit transaction`
- CTA label becomes `Save changes` or `Update transaction`
- fields are prefilled

Rejected differences:

- different field order
- different input styling
- a more “settings-like” layout that diverges from add transaction

The user should feel like they are editing the same form, not navigating to another product surface.

## Design Tokens That Override Mockup Drift

If an implementation detail appears visually appealing in a mockup but conflicts with the approved Conscia tokens, the tokens win.

Priority order for this work:

1. approved Conscia tokens and component rules
2. approved screen structure from this spec
3. visual styling cues from mockups

Examples:

- use `deepNavy`, not arbitrary blue
- use `paper`, not stark white screen backgrounds
- use the v2 floating-label field spec, not generic outlined fields
- use the existing typography scale, not ad hoc font sizing

## Testing Expectations

This pass should update tests to validate approved structure rather than stale implementation details.

Tests should verify:

- list screen shows centered title, chip rail, grouped date sections, and transaction rows
- add screen shows the approved section order
- add screen uses the v2 field widgets for merchant/source and date
- edit screen mirrors the add screen structure with prefilled values
- recurring controls expand only when enabled

Tests should stop depending on brittle implementation details that are not part of the approved design, such as very specific internal widget composition when a higher-level design contract is more important.

## Implementation Notes

- Prefer adapting existing reusable widgets over adding one-off screen-local clones.
- If the current amount hero widget and segmented controls are close to spec, refine them rather than replace them.
- If merchant/source and date fields cannot fully adopt the floating-label widget without harming form behavior, fix the shared widget first instead of special-casing the transaction form.
- Keep the work limited to transaction screens and any genuinely shared primitives needed to align them.

## Acceptance Criteria

The redesign is complete when:

- transactions list feels airy and legible on iPhone SE
- add and edit transaction share the same structure
- merchant/source and date fields use the approved floating-label v2 treatment
- scope is explicitly labeled
- category presentation avoids duplicate labeling
- recurring remains compact by default and expands cleanly
- the screens use Conscia tokens rather than drifting toward generic iOS finance-app styling
- updated tests reflect the approved UI contract and pass
