# Web Mascot Storytelling Design

## Summary

Redesign the public `web/` marketing page around a playful, character-led storytelling structure that explains Conscia’s product concept first, builds trust second, and sends users into the app for the real onboarding and sign-up flow.

The devil, angel, and receipt become recurring mascot characters across the page, but only the hero is animated. The app icon remains the official brand mark for navigation, identity, and meta surfaces.

## Goals

- Explain Conscia’s core metaphor instantly: impulse, reason, and the spend itself.
- Make the page feel playful and character-led without becoming childish.
- Build trust through concrete feature explanations and a clear product arc.
- Keep the primary call to action focused on opening the app, not signing up on the website.
- Create section layouts that can later accept real device screenshots once the app has been validated on physical devices.

## Non-Goals

- No web-native sign-up flow in this pass.
- No animated mascots outside the hero.
- No final screenshot integration in this pass.
- No mascot takeover of the logo system or utility icon language.

## Page Strategy

The page should read like storytelling chapters with product proof embedded inside each chapter.

Narrative arc:

1. Meet the inner voices
2. Catch the spend
3. Reflect without shame
4. Build better habits
5. Open the app

This preserves product clarity while making the mascot concept feel intentional rather than decorative.

## Information Architecture

### Hero

Purpose:
- Explain the product metaphor immediately
- Introduce the mascots
- Establish the tone of the page

Structure:
- Left: headline, supporting copy, primary and secondary CTA
- Right: the only animated mascot scene on the page
- Supporting proof strip or short stat row below the copy

Behavior:
- Animated hero only
- Devil, angel, and receipt sit in a readable push-pull composition
- Background uses the red / gold / blue cloudy galaxy motif
- Motion should feel premium and readable, not like a mini-game

Messaging direction:
- Conscia is the financial conscience inside a spending decision
- It helps users catch impulse, reflect without shame, and improve habits over time

CTA:
- Primary: open the app
- Secondary: see how it works

### Chapter 1: Catch the Moment

Purpose:
- Explain that Conscia helps before and immediately after a spending moment

Feature focus:
- Pre-purchase assistant
- Fast transaction logging
- Support for real-world spending flow

Visual direction:
- Static mascot/product composition
- One strong chapter card or visual surface
- Layout should feel product-real without requiring final device screenshots

Copy direction:
- Focus on clarity, speed, and reduced friction
- Emphasize that users can act quickly without losing context

### Chapter 2: Reflect Without Shame

Purpose:
- Make clear that Conscia is not a guilt app

Feature focus:
- Reflection prompts
- Regret memory
- Pattern awareness

Visual direction:
- Softer composition than chapter 1
- Still character-led, but less confrontational
- Reflection and emotional reset should feel supportive

Copy direction:
- Reflection helps users notice what happened
- The product encourages honesty and learning, not punishment

### Chapter 3: Build Better Habits

Purpose:
- Show the long-term payoff of using Conscia

Feature focus:
- Budgets
- Insights
- Recurring transactions
- Habit-building over time

Visual direction:
- More structured and trustworthy
- Can use static product-story surfaces that later accept real screenshots

Copy direction:
- Focus on progress, consistency, and better decision-making over time

### Final Chapter / CTA

Purpose:
- Convert user understanding into action
- Reinforce trust and platform clarity

Content:
- Platform support
- Short trust reassurance
- One clear CTA to open the app

Rules:
- Do not ask users to sign up on the website
- Keep the web page as the explainer and trust-builder
- Let the app handle actual onboarding and account creation

## Visual Language

### Brand Balance

- The app icon remains the core brand mark.
- The mascots are recurring editorial characters.
- Mascots should never replace the logo in navigation, footer branding, or product utility spots.

### Motion

- Animation is limited to the hero.
- All later mascot appearances are static or extremely subtle.
- The hero should feel alive but controlled.

### Atmosphere

- Red / gold / blue cloudy backgrounds can repeat across sections as a motif.
- Intensity can vary by chapter:
  - warmer for impulse / capture
  - softer for reflection
  - cooler / steadier for habit-building

### Layout Rhythm

Alternate section rhythm so the page does not become repetitive:
- one chapter more copy-led
- next chapter more visual-led
- then back again

### Screenshots Later

Design sections so real app screenshots can be dropped in later without redesigning the page.
For this pass:
- use branded chapter surfaces
- avoid fake device screenshot comps that will go stale immediately

## Content Principles

- Lead with the metaphor, but always anchor it in real product behavior.
- Avoid generic fintech language.
- Keep the tone warm, playful, and confident.
- Do not let the mascots turn the page into parody.
- Make the product feel emotionally intelligent and useful.

## Technical Direction

Target:
- redesign the Astro/Tailwind page in `web/`

Expected changes:
- hero component
- section layout/components for chapter flow
- mascot art usage in public images
- supporting copy updates across the main page

Implementation guidance:
- hero gets the only animated mascot composition
- later sections reuse the same art system but stay static
- page structure should remain responsive and work cleanly on mobile and desktop
- avoid overfitting layout to placeholder imagery

## Testing and Validation

Implementation should be validated with:
- local web build
- mobile and desktop viewport checks
- visual consistency against the approved onboarding direction

Post-device-validation follow-up:
- replace placeholder product-story surfaces with real screenshots where helpful

## Open Decisions Already Resolved

- The web page should explain the concept and build trust first.
- Sign-up should remain inside the app.
- The page should feel playful and character-led.
- The structure should use storytelling chapters with product proof inside each chapter.
- Mascots should be animated only in the hero.
- Real device screenshots will come later, after app validation on actual devices.
