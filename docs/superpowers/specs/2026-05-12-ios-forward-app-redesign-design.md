# iOS-Forward App Redesign Design

**Date:** 2026-05-12
**Status:** Approved for implementation planning
**Feature:** Full mobile app UI redesign using Conscia Design Language v2

## Goal

Redesign the Conscia mobile app so it feels clearly more native to iOS, visually more intentional, and more consistent across the entire product, while preserving Conscia’s distinct identity.

The redesign should:

- Follow the provided **Conscia Design Language v2**.
- Use the attached mockup direction as inspiration, but stay grounded in the actual app that exists today.
- Cover every routed screen plus meaningful empty/loading/error states, sheets, modals, dialogs, and confirmations.
- Preserve mascot identity, color tokens, typography tokens, and the current 5-destination navigation structure.

The redesign should not:

- Redesign the `web/` marketing site in this pass.
- Invent new product capabilities that do not already exist.
- Change backend contracts unless explicitly called out as a separate product/data-model decision.

## Product Principles

- **iOS-forward, not iOS cosplay.** Use native-feeling layout, hierarchy, motion hints, and controls without forcing UIKit visual cloning where the app already has its own identity.
- **Emotion where it matters, restraint where it helps work happen.**
- **Do not invent what we do not have.** Redesign structure, hierarchy, and polish, but do not add fictional features, summaries, or flows that the current app cannot support.
- **Conscia must still feel like Conscia.** The Angel and Devil mascot sprites remain first-class identity elements.
- **Forms should feel calmer and less punitive.** Inline guidance and floating labels replace banner-heavy validation.
- **Dense data should feel organized, not fragmented.** Repeated rows belong in grouped cards with separators unless there is a strong reason to isolate them.

## Scope

This redesign covers the mobile app only.

Screen families in scope:

- Onboarding and auth
- Main shell and floating navigation
- Dashboard / Home
- Transactions list, add/edit, and detail
- Assistant / pre-purchase flow
- Receipts scan and review
- Journey
- Insights
- Budgets
- Categories
- Settings
- Profile
- Shared Conscia / family screens
- Service status

State coverage in scope:

- Empty states
- Loading states
- Error states
- Success and confirmation states where the screen meaning changes
- Bottom sheets
- Full-screen modals
- Alert/confirm dialogs
- Pickers

## Existing Constraints

The redesign must preserve:

- Existing color tokens from v2
- Existing typography tokens from v2
- Mascot sprites exactly as the visual identity
- Existing 5-tab app structure
- Existing core product model and current information architecture unless explicitly changed

The redesign must adapt existing implementation reality:

- The app currently has richer surfaces in some areas and older UI patterns in others.
- The backend currently stores `locale`, not a separate formatting preset.
- The current user model does not include a name field or profile photo field.

## Visual Direction

Use the approved **Emotion-Tiered Hybrid** direction.

This means:

- Most screens use a warm `paper` canvas with white cards and restrained borders.
- Important, identity-defining screens get a richer editorial hero treatment.
- Gradients appear in contained hero surfaces, not as full-screen backgrounds.
- Visual richness supports emotion, reflection, and product identity rather than making every screen decorative.

### Gradient Hero Tier

These screens should get the richer editorial treatment:

- Home
- Journey
- Assistant
- Transaction Detail
- Insights
- Profile
- Shared Conscia

### Paper-Native Utility Tier

These screens should stay lighter and more functional:

- Sign in / sign up / verify email
- Setup defaults
- Onboarding profile questions
- Transactions list
- Add/edit transaction
- Budgets
- Categories
- Service status
- Family invites and member management
- Receipt review

### Transaction Screen Rules

Transaction screens follow the utility-tier treatment even after the broader redesign.

Rules:

- Transactions list stays in the paper-native utility tier.
- On iPhone SE, the list uses a single horizontal chip rail and does not add a separate `Personal / Family` segmented control.
- Add and edit transaction share the same structure.
- `Merchant` / `Source` and `Date` use the v2 floating-label filled-field treatment.
- `SCOPE` remains an explicit section label rather than relying on implied context.
- Category selection stays a single-row horizontal rail on SE.
- Recurring stays compact by default and expands inline only when enabled.

### Dark Utility Exception

`Scan Receipt` keeps the dark live-camera treatment, but the chrome should still feel more iOS-native and consistent with the rest of the redesign.

## Global Layout System

### App Bars

- Use centered iOS-style titles.
- Back control is the chevron `‹`, not a large Material arrow.
- Default title treatment: 17sp / 700 / Poppins centered.
- Add a subtle bottom divider only when the content is scrollable and the bar is acting as a chrome layer.

### Screen Padding

- Default horizontal padding: 20px.
- Respect the existing spacing scale from v2.
- Screens should feel more breathable than today, especially in forms and list sections.
- **Hero bleed rule:** emotion-tier editorial heroes should bleed to the device edges and into the top safe area. The hero surface starts at `x=0` with bottom-only rounding, while the content inside the hero keeps intentional internal padding. Non-hero content below the hero must return to normal screen padding.
- Do not solve hero bleed by removing page padding globally. Only the hero bleeds; sections, lists, and form/detail groups keep their standard horizontal rhythm.

### Section Labels, Titles, And Subtitles

Section headings should behave more like navigation landmarks than content headlines.

Use the updated `sectionTitle` treatment for major content sections:

- uppercase text
- 12sp Inter
- 800 weight
- 0.8-1.0 letter spacing
- `mutedInk`
- placed above the section subtitle and content group

This should feel related to `FormLabel`, but slightly more prominent:

- `FormLabel`: 11sp, uppercase, compact, used inside forms/detail groups such as `AMOUNT`, `CATEGORY`, `DETAILS`, `SCOPE`
- `sectionTitle`: 12sp, uppercase, more vertical spacing, used for screen structure such as `REGRET PATTERNS`, `MERCHANT SPOTLIGHT`, `RECENT SIGNALS`, `BUDGETS`

Section subtitles should stay readable and explanatory:

- 13-14sp Inter
- regular weight
- `mutedInk` or `softInk`
- line height around 1.35
- placed directly under the section label

Avoid using large title-case section headings when the heading is only grouping related rows. Reserve larger Poppins title treatments for hero copy, card titles, modal titles, and true editorial statements.

### Surfaces

- Primary screen canvas: `paper`
- Standard cards: white, 1px `border`, no drop shadow in light mode
- Large grouped lists should prefer one rounded card with internal separators
- Avoid stacking many isolated micro-cards when the content is really one list

### Swipe Actions

Swipe gestures should reveal actions without visually bleeding through row content.

- The foreground row must remain opaque while it moves; use the screen canvas (`paper`) or the row's actual surface as the sliding layer background.
- Revealed actions use separate rounded tiles, not one full-width flat color strip.
- Destructive swipe actions use `expenseSoft` tile backgrounds with `expense` icon/text.
- Neutral utility actions use `navySoft` or another approved soft token with `deepNavy` icon/text.
- Swipe actions should stay compact and icon-led, with a short label for clarity.
- Apply the same treatment across transaction rows, budget rows, notification rows, and any future swipeable list item.

## Navigation Shell

The bottom navigation should use the approved **floating integrated dock** pattern.

Rules:

- Keep 5 destinations.
- Remove text labels.
- Let icons carry the meaning.
- Use one floating pill dock above the bottom edge.
- The center `Scan` action stays highlighted and visually larger.
- The center action remains integrated into the dock silhouette rather than floating as a separate detached FAB.

This changes the emotional tone of the app shell without changing the actual navigation structure.

## Inputs And Form Patterns

### Floating Label Fields

Use the v2 floating-label input pattern across the app.

States:

- Empty / idle: frosted fill + 1.5px border
- Focused: white background + 2px `deepNavy` border
- Filled / unfocused: frosted fill + raised muted label
- Error: white background + 2px `expense` border + raised error-colored label

Rules:

- The field owns its label.
- Do not duplicate a field label above the component if the component already has a floating label.
- Section labels remain appropriate for non-field groups like `Scope`, `Preferences`, `Achievements`, etc.

### Validation

Auth and field validation must switch to the approved v2 patterns:

- Screen-level auth failures: inline soft `expenseSoft` note between the last field and CTA
- Field-specific validation: inline helper text directly below the field
- No dismissible Material banners for auth errors
- No toast/snackbar-style validation feedback

### Password Fields

- Eye toggle stays on the trailing edge
- Use the v2 visual treatment rather than a boxed Material default look

## Selection Semantics

Single-select lists use the **flat settings-list + trailing checkmark** pattern.

Rules:

- Use flat rows with internal separators, not radio dots.
- Selected row shows one trailing `check_rounded` icon in `deepNavy`.
- Unselected rows reserve no visible indicator.
- Primary option title is bold, usually 14sp Inter / 700, `ink` or `deepNavy` when selected.
- Optional subtitle is regular-weight, muted, and smaller than the title.
- Do not wrap these lists in extra cards unless the surrounding surface already requires it.

Examples:

- Region format picker
- AI personality intensity picker
- Profile spending style / income / occupation / household pickers
- Onboarding spending style, monthly income, occupation, and household choices

Use chips only for compact horizontal rails where the item set is browse/filter-like rather than a vertical “choose one” list.

## Lists, Rows, And Grouped Cards

Dense lists should prefer grouped cards with separators.

Examples:

- Transactions grouped by date
- Settings groups
- Members list
- Categories list
- Invite lists
- Family activity

Avoid:

- One tiny card per row when the content is obviously one list
- Unnecessary visual fragmentation

The grouped-card pattern is especially important for:

- Shared Conscia
- Settings
- Transactions list
- Categories
- Service status

## Mascot Usage

Mascot sprites remain exactly part of the Conscia identity.

Rules:

- Use the actual Angel and Devil sprite art, not substitute emoji or generic illustration stand-ins
- Use mascots intentionally on emotion-tier surfaces
- Keep mascot moments meaningful rather than decorative wallpaper

Primary mascot surfaces:

- Assistant
- Journey
- Home nudges
- Insight/editorial highlight moments
- Transaction reflection surfaces

## Screen Family Decisions

### Home

- Keep existing dashboard meaning: balance, nudges, recent transaction framing, and overall signal surfaces already present in product
- Add a contained editorial hero
- Keep list data grouped and scannable

### Transactions List

- Keep filters and grouped date sections
- Use grouped list cards per date section
- Avoid inventing new dashboard-like metrics here

### Add/Edit Transaction

- Keep current product shape: amount, scope, category, merchant/notes, date, recurring
- Use floating-label fields and more intentional spacing
- Category remains a clear select/picker, not a fake mini-dashboard

### Transaction Detail

- Keep the current actual purpose: amount, metadata, feeling, AI reflection access, edit/delete
- Use a richer hero because this is an important reflective surface
- The transaction snapshot hero follows the hero bleed rule: it reaches the top/device edges under the sticky header, uses bottom-only rounding, and keeps `DETAILS` and feeling controls in padded utility content below.

### Assistant

- Keep the current actual structure: item, amount, category, scope, context, AI responses
- Use mascot-led editorial emphasis here

### Journey

- Preserve XP, quests, mascot moments, and achievements
- Include the compact achievements strip language approved from the reference:
  - earned badges first
  - locked mystery states after
  - `All ›` affordance

### Insights

- Do not invent new information architecture
- Preserve the current product structure and meaning
- Use the richer editorial tier because Insights is an important reflective surface
- Use a full-bleed top hero that reaches into the top safe area, matching the Home hero behavior
- Use one transparent sticky header over the hero that becomes translucent on scroll
- Do not use Angel / Devil emoji as mascot substitutes
- If mascots appear, use the actual Angel and Devil sprite assets; otherwise use product/category iconography
- Put the strongest insight summary in the hero, then place the pulse summary immediately below it
- Prioritize the flow: hero, regret pulse, regret patterns, merchant spotlight, category trend, recent signals
- Section headings use the updated uppercase muted `sectionTitle` treatment with subtitles underneath
- Repeated insight rows should live in grouped cards with separators rather than separate cards per row
- Keep all insight content grounded in the current providers and avoid inventing new analytics

### Shared Conscia

- Match the approved hero treatment closely:
  - centered household card
  - title / subtitle / owner rhythm
  - grouped cards below for budgets, activity, and members

### Settings

- Match the approved grouped layout:
  - profile card
  - Shared Conscia card
  - Budgets & Categories
  - Preferences
  - Subscription
  - Data & About

### Scan Receipt

- Keep the dark camera feel
- Use simpler, more native-feeling top chrome and bottom controls

### Review Receipt

- Use grouped editing fields and confidence messaging
- Stay utility-first

## Locale / Formatting Wording

We should preserve the current backend `locale` capability, but the UI must stop implying app-language switching.

Approved wording direction:

- Settings row: `Currency & Region Format`
- Picker title: `Region Format`
- Helper copy: `Changes how numbers and dates are shown. App language stays in English.`

Approved formatting examples:

- `Philippines / US` → `1,234,567.89`
- `European` → `1.234.567,89`
- `French / Swiss` → `1 234 567,89`
- `Indian` → `12,34,567.89`

Implementation note:

- This is a frontend wording/option-mapping change.
- Under the hood, the app can still map those choices onto the existing locale-based contract.

## Empty, Loading, Error, And Confirmation States

### Empty States

- Keep them optimistic and instructional
- Make the next action obvious
- Avoid overly decorative illustrations that add no clarity
- Do not wrap empty states in content cards; empty is a quiet centered state, not a feed item
- Use the shared `EmptyState` pattern for icon + title + subtitle, matching the Transactions empty screen
- Keep copy short: one confident title and one helper sentence

### Loading States

- Prefer calm, structured loading
- Use skeleton structure where it helps preserve layout expectations

### Error States

- Use embedded retryable state cards for screen failures
- Avoid visually overwhelming failure treatment unless truly necessary

### Confirmations

- App-owned destructive confirmations use a pull-up confirmation sheet, not a centered dialog
- Use the shared confirmation sheet language: `paper` surface, 28px top corners, centered handle, concise title, muted helper text, full-width destructive pill button, and outlined cancel button below
- Keep copy specific and calm: state what will be deleted, say it cannot be undone, and avoid paragraph-heavy legal text
- Reserve native/system alerts for OS permissions or platform-owned prompts only

## Sheets And Overlays

All bottom sheets should share one language:

- 28px top radius
- centered drag handle
- `paper` background surface, not default Material white
- clearer hierarchy
- same field treatment as full screens

Important sheets/pickers to redesign consistently:

- Currency picker
- Region format picker
- Subscription sheet
- Budget form
- Category form
- Reflection sheet
- Rename family space

## Backend-Impacting Discoveries

These are not just cosmetic UI changes and should be treated as explicit product/data work if implemented:

### User Name

The current backend user model and `/api/v1/users/me` payload do **not** have a name field.

Current reality:

- `User` has `Email`, preference fields, onboarding/profile fields, etc.
- `UserProfileUpdateDto` does not include `Name`
- Flutter user model does not include `name`

Implication:

- Showing and editing a real user name requires backend/API/model changes unless we intentionally keep using email-derived display.

### Profile Picture Upload

The current backend does **not** expose a user profile photo field or upload flow.

Implication:

- Adding upload/change photo requires:
  - user model field such as `ProfilePhotoUrl`
  - storage/upload path
  - API support
  - client support

These should be tracked separately from pure UI refactor work.

## Implementation Boundaries

The redesign work itself should focus on:

- Theme/token alignment
- Navigation shell redesign
- Shared component primitives
- Screen-by-screen migration to approved patterns
- State surface redesign

It should not silently bundle:

- user profile data model expansion
- photo upload infrastructure
- locale/formatting backend redesign
- new insights/business logic
- new dashboard metrics

## Testing Strategy

### Widget / Screen Tests

Update and extend tests around:

- Main shell
- Sign in and auth validation
- Onboarding selection flows
- Transactions list and form
- Assistant
- Journey
- Settings
- Family screens
- Receipt screens

### Visual Regression Focus

Pay attention to:

- grouped list card spacing
- floating-label input states
- radio vs check selection consistency
- dock navigation behavior
- mascot rendering and placement

### Manual QA Focus

- all important screens still preserve actual product meaning
- no duplicated labels on fields
- grouped lists remain readable on narrow screens
- dock does not interfere with safe-area interactions
- formatting wording no longer implies language switching

## Approved Design Decisions Summary

- Use **Emotion-Tiered Hybrid**
- App only, not web
- Important screens get richer hero treatment; utility screens stay calmer
- Floating integrated icon-only dock with centered scan
- Real mascot sprites remain central to product identity
- Repeated rows should usually live in grouped cards with separators
- Inputs use floating labels
- Auth errors become inline soft notes
- Radio dots for small unrelated single-select choices
- Checks for grouped list-card pickers like currency and region format
- Keep Insights grounded in what already exists; add editorial emphasis only
- Keep locale under the hood, but message it as region formatting in the UI
- Name and profile photo are backend-impacting, not just visual tweaks
