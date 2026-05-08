# Alter Ego Loader Design

## Overview

This design replaces the current `ConscienceLoader` motion language with a more intentional image-based animation built around the `conscia_alterego.png` artwork. The goal is to make the AI thinking/loading state feel alive and playful without becoming creepy, haunted, or visually noisy.

The loader should be reusable across both:

- `PrePurchaseScreen`
- transaction reflection loading in `TransactionDetailScreen`

The same visual system should apply in both places, with only copy differences where needed.

## Goals

- Use the alter-ego artwork as the centerpiece of the AI thinking state.
- Make the motion feel like inner conflict or active deliberation.
- Keep the effect premium and readable on mobile, not game-like or uncanny.
- Replace the current drifting mini-badge motion that made the loader feel unsettling.
- Reuse one shared component across both assistant and reflection flows.

## Non-Goals

- This does not require animated SVG or Lottie tooling.
- It does not redesign the app icon or launcher assets.
- It does not replace every spinner in the app; it is specifically for AI-thinking states first.
- It does not require a fully different loader for assistant vs reflection.

## Current Problem

The existing loader in `app/lib/widgets/conscience_mark.dart` animates small devil and angel badges around the brand mark. That motion reads as floaty and uncanny rather than intentional. The center mark itself appears to drift or wobble, which makes the interaction feel “haunted” instead of thoughtful.

The desired behavior is closer to:

- stable center
- environmental tension around it
- subtle clash energy
- clearer visual storytelling

## Chosen Approach

Use the raster alter-ego image as the centerpiece of a Flutter-built animation.

The animation remains code-driven:

- aura glows
- ring rotation
- clash pulse
- slight breathing scale
- optional small financial spark

The image itself is not sliced or animated internally. The scene animates around a stable central illustration.

This gives the personality of the provided artwork without requiring fragile asset-specific animation tooling.

## Visual Structure

The loader is built as a layered stage:

1. **Red devil aura**
   - soft glow on the left side
   - expands slightly during clash moments

2. **Blue angel aura**
   - soft glow on the right side
   - mirrors the devil aura with balanced motion

3. **Rotating battle ring**
   - very subtle circular ring around the image
   - slow, premium-feeling motion rather than flashy rotation

4. **Central alter-ego image**
   - clipped to a circular frame
   - remains visually anchored in the center
   - only slight breathing scale, no constant lateral wobble

5. **Clash flash**
   - quick, restrained pulse at the center
   - suggests conflict or comparison, not explosion

6. **Financial spark**
   - small optional currency or receipt-related glow above/below the mark
   - should feel like an accent, not a mascot

## Motion Principles

The motion must follow these rules:

- center remains stable
- motion comes from aura, pulse, and ring layers
- shake only appears as a short clash accent, if at all
- no constant side-to-side drifting
- loop should feel calm enough to watch repeatedly

### Tone Target

The animation should feel like:

- “your conscience is weighing this”
- “two sides are actively in tension”

It should not feel like:

- a haunted logo
- a fighting game
- a cartoon battle
- an idle spinner with random wobble

## Surface Usage

### Pre-Purchase Assistant

Use the loader prominently while the AI is generating the response. Keep the copy beneath it conversational, for example:

- `Your conscience is weighing both sides...`

The loader can be slightly larger here than in reflection.

### Reflection Sheet

Use the same loader while AI reflection content is being generated. Keep the tone slightly calmer through copy, but the component itself should remain the same visual system so the AI identity stays consistent.

Possible copy:

- `Looking at the full picture...`
- `Replaying the decision with a little distance...`

## Asset Strategy

The implementation should use the provided alter-ego image asset rather than the existing vector mark for this loader.

Requirements:

- asset should remain circular or be clipped into a circular presentation
- background treatment around the image should not assume a dark full-screen scaffold
- the loader must still look good on the app’s lighter redesigned surfaces

## Technical Direction

Implement as a new or refactored shared widget in the Flutter app, likely replacing or extending `ConscienceLoader`.

The component should:

- accept `size`
- accept optional `label`
- remain usable inside narrow modal or sheet layouts
- avoid layout jumps when shown inline

It should continue to use Flutter animation primitives (`AnimationController`, `AnimatedBuilder`, transforms, shadows, pulses) rather than adding a new animation dependency.

## Accessibility and Performance

- keep loop smooth and lightweight
- avoid excessive blur/shadow counts that cause jank on lower-end devices
- support reduced-motion fallback later if needed, though reduced motion is not required in this first pass
- text label should remain readable and separate from the visual effect

## Acceptance Criteria

- `PrePurchaseScreen` uses the new alter-ego loader while generating AI output
- reflection loading uses the same loader system
- the old creepy drifting mini-badge effect is removed from the AI loader path
- the center illustration feels stable
- the animation reads as “deliberation/conflict” rather than “haunted motion”
- no new animation package is required

## Out of Scope Follow-Up

Possible future expansions, not required now:

- separate intensity variants for different AI personality settings
- subtle alternate copy/tempo between assistant and reflection
- reduced-motion mode
- loader reuse on additional AI surfaces outside assistant/reflection
