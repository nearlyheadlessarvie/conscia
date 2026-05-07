# App Redesign, Voice Input, Regret Alerts, and Landing Page Design

## Overview

This initiative starts a broader app-wide visual refresh while also completing two unfinished product systems and redesigning the public marketing site. The work is intentionally treated as one umbrella initiative with multiple ordered subprojects, but it will be implemented on a single branch so the design language stays coherent end to end.

The four streams are:

1. shared design system, app shell, and core screen templates
2. full app-wide screen redesign built on those templates
3. completion of the unfinished voice input flow
4. implementation of a full regret-memory alert system
5. redesign of the `web/` landing page using the same product language

The guiding principle is that the redesign foundation comes first. Voice input, regret alerts, and landing-page work should not invent parallel UI patterns. They should all reuse the same updated primitives, spacing rhythm, component treatment, and icon language introduced by the new app foundation.

## Goals

- Establish a coherent, reusable visual language across the Flutter app and Astro landing page.
- Redesign the app shell and highest-traffic screens so the rest of the app can follow a consistent pattern.
- Complete voice input in a way that feels like a first-class input mode, not an add-on.
- Replace the current lightweight regret prompts with a real regret-memory alert system that is observable, deduplicated, and reusable across surfaces.
- Redesign the public landing page so it reflects the app’s real product identity and updated UI.

## Non-Goals

- This effort does not try to finish every speculative future feature in the roadmap.
- It does not require a new backend speech-to-text architecture beyond what is necessary to finish the currently unfinished voice input flow.
- It does not require a new AI model strategy beyond what the existing app already supports.
- It does not attempt to finalize a bespoke brand-logo SVG workflow from scratch. Existing brand mark assets can remain provisional while the UI system is improved.

## Current Context

The codebase already contains several pieces of Phase 4 groundwork:

- shared theme files in `app/lib/core/theme/`
- a redesigned `AmountInputField`
- the new Conscience mark and loader in `app/lib/widgets/conscience_mark.dart`
- a branded category badge system in `app/lib/core/constants/category_icons.dart`
- an emphasized `MainShell`
- an unfinished `voice_input_button.dart`
- dashboard alert surfaces and regret prompt widgets
- a separate Astro marketing site under `web/`

The app currently suffers from two main design issues:

- multiple visual languages coexist at once, especially between onboarding/profile/settings and the newer assistant/transaction/category surfaces
- system-level features like voice input and regret memory are present only as partial or local experiences rather than coherent product systems

## Architecture

### 1. Shared Design System Foundation

The first implementation slice introduces a shared redesign foundation for the Flutter app. This is not a separate package; it is a focused expansion of the existing theme and widget layers.

It should define:

- updated color/token usage in `app/lib/core/theme/`
- shared layout rhythm and section spacing
- standardized card treatments
- standardized hero-input surfaces
- standardized chip groups and selection surfaces
- standardized alert/banner components
- reusable empty/loading states

The design system should formalize what already works in the newer assistant/category surfaces instead of replacing the app with something unrelated.

### 2. Core Screen Templates

The redesign foundation will be expressed through four canonical screen templates:

#### Feed Dashboard

Used by `DashboardScreen` and later insights-style feed surfaces.

Traits:
- calmer sticky top chrome
- clearer section rhythm
- modular alert, budget, regret, and activity cards
- stronger editorial flow, less “stack of widgets”

#### Hero Input Screen

Used by `TransactionFormScreen` and `PrePurchaseScreen`.

Traits:
- amount input as the visual anchor
- predictable field hierarchy below the amount input
- smart suggestions and voice input integrated as input tools, not bolted-on controls
- clearer structure for category, counterparty/source, notes, and location-aware suggestions

#### Preferences / Profile Surface

Used by `SettingsScreen` and `ProfileScreen`.

Traits:
- sectioned preference groups
- consistent chip/card selection patterns
- cleaner toggles, pickers, and account panels
- same icon language as onboarding

#### Guided Wizard Surface

Used by onboarding and future guided flows.

Traits:
- cleaner step framing
- spacious, welcoming selection modules
- same primitives as settings/profile, but with onboarding pacing and hierarchy

### 3. App-Wide Redesign

After the foundation is in place, remaining screens should be migrated onto these shared templates and primitives rather than redesigned freehand.

Priority order after the first slice:

1. dashboard
2. transaction entry
3. pre-purchase assistant
4. settings and profile
5. onboarding
6. remaining secondary surfaces like budget management, insights lists, receipt review, and transaction detail

### 4. Voice Input Completion

Voice input should be completed inside the shared hero-input pattern.

Scope:
- finish the existing `voice_input_button.dart` path
- support both `TransactionFormScreen` and `PrePurchaseScreen`
- use voice to assist with amount, likely category, and counterparty/source where possible
- degrade gracefully on unsupported platforms, especially web

Behavior:
- voice is assistive, never blocking
- it should fill fields or offer suggestions, not silently submit data
- unsupported states should be clearly explained without breaking the form

### 5. Regret-Memory Alert System

The existing regret prompts and reflection nudges should become a unified alert system.

The system should support alert types such as:

- repeated regret in a merchant
- repeated regret in a category
- growing “not sure” uncertainty trend
- cooling-off recommendation after clustered impulse spending
- reflection follow-up after regret events
- monthly regret pattern summaries where appropriate

System requirements:
- deduped and prioritized alerts
- reusable alert model
- reusable rendering components
- support for dashboard banners/cards first
- later extensibility into transaction detail and insights

### 6. Landing Page Redesign

The Astro site under `web/` should be redesigned after the app’s core screens are visually stable.

Goals:
- align it with the updated app visual language
- use real updated app surfaces in hero/mockup sections
- clarify the “financial conscience” value proposition
- reduce generic SaaS layout feel
- make pricing, roadmap, and product differentiation more coherent

## Sequencing

The agreed implementation order is:

1. shared design system + app shell + core screen templates
2. key app screens redesign
3. voice input completion
4. regret-memory alert system
5. landing page redesign

All work happens on a fresh main-based feature branch, but the branch is intentionally not pushed or PR’d automatically at completion. The user wants to review the branch locally before deciding how to integrate it.
