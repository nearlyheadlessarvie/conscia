# Level Up Confetti Design

Date: 2026-05-22

## Goal

Add a continuous celebratory confetti treatment to the level-up screen without changing the rest of the journey flow. The effect should feel like a full celebration, but still stay readable and compositionally calm enough for the existing ceremonial layout.

## Scope

This change applies only to the level-up celebration screen in `app/lib/screens/journey/level_up_screen.dart`.

Included:
- animated confetti on the level-up screen
- upper-half-only celebration field
- paper pieces and streamer shapes
- continuous looping motion that does not feel like an obvious reset

Not included:
- old icon cleanup in other screens
- dark mode treatment
- sound, haptics, or particle effects elsewhere in the app
- package-based confetti dependency

## Recommended Approach

Use a custom painter-backed animated confetti layer.

Why:
- best control over density, drift, and restart feel
- easiest way to keep the celebration in the upper half only
- avoids generic party-cannon behavior from a package
- keeps the effect aligned with the Conscia visual tone

## Visual Behavior

The confetti layer will:
- render behind the medallion and text stack
- stay concentrated in the upper half of the screen
- use paper rectangles plus ribbon/streamer shapes
- continuously loop with staggered particle timing
- thin out before the XP pill and CTA area

The effect should read as “always in motion” rather than “burst, stop, reset.”

## Motion Model

Use one repeating animation controller that drives normalized time.

Each particle gets:
- seeded start offset
- vertical speed
- horizontal drift
- rotation speed
- size
- opacity
- shape kind: paper piece or streamer
- color from the existing app palette

Particles should recycle independently so the screen never visibly hard-resets all pieces at once.

## Layout Rules

- Confetti is clipped to the upper half region of the screen.
- Density is strongest around the medallion band and fades downward.
- Compact layouts use fewer particles than regular layouts.
- The effect must not intercept touches.

## Rendering Direction

Use the existing level-up `Stack` and add a dedicated confetti layer between:
- atmosphere background painter
- main level-up content column

This keeps the ceremony copy readable while still feeling celebratory.

## Architecture

Add a focused widget near the level-up screen, preferably:
- `app/lib/screens/journey/level_up_confetti.dart`

Responsibilities:
- `LevelUpConfetti`: owns animation lifecycle and clipping region
- custom painter: draws paper pieces and streamers from seeded particle data

Keep the particle model local to this feature. Do not generalize into a global particle system.

## Performance

- keep particle count modest
- avoid per-frame allocations where possible
- prefer deterministic seeded particle generation
- keep painter repaint-driven by a single controller

## Testing

Add focused app tests that verify:
- level-up screen still renders
- confetti layer is present on the screen
- compact and standard layouts still show core content correctly
- preview routes still open the level-up screen without regression

Visual fidelity of animation will be validated manually in web and device preview.

## Risks

- too much density can make the page noisy
- too little variation can make looping feel fake
- particles extending too low can reduce CTA readability

Mitigation:
- keep the effect upper-half only
- use staggered particle timing
- tune compact-screen density separately
