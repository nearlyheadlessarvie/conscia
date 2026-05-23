# Web System Atmosphere Design

Date: 2026-05-23

## Goal

Bring the marketing site into the same atmosphere as the current app while repositioning the homepage around Conscia as an all-in-one money system.

This pass should make the site feel like a natural extension of the shipped app screens:
- soft ivory surfaces
- pale lavender and warm gold hero washes
- deep navy typography
- rounded white cards
- calm editorial spacing
- broad product-system messaging instead of a narrow single-journey story

This pass also updates web icon assets and production store links, but does not replace the existing text lockup in the navigation or footer.

## Scope

In scope:
- rewrite and restage the homepage around Conscia as a broad money system
- align the web atmosphere with the current app screenshots
- update icon asset usage on the web to the new app icon
- wire the production App Store and Google Play links into existing badge surfaces
- refresh the simulated app imagery so it mirrors current product screens more closely

Out of scope:
- changing the core brand wordmark or introducing a new nav/footer logo system
- redesigning legal pages beyond asset inheritance from shared layout/components
- changing app code or mobile UI behavior
- adding new pricing flows, lead capture, analytics, or extra site sections not needed for the homepage pass

## Product Positioning

The homepage should lead with Conscia as one place to:
- track spending
- reflect on purchases
- manage budgets
- scan receipts
- surface patterns and regret signals
- coordinate shared household planning

The emotional tone should remain calm and reflective, but the information architecture should make the product breadth obvious much earlier.

The site should no longer feel primarily like a “pause before spending” landing page with supporting extras. It should feel like a complete money system with reflection as one of its defining strengths.

## Atmosphere Reference

The app screenshots establish the atmosphere to match:
- editorial serif headings paired with clean sans-serif body text
- light cream backgrounds with pale lavender and gold-tinted hero gradients
- soft white cards with subtle shadows and thin borders
- deep navy as the primary text and structure color
- accent colors that come from in-app category and signal tones, but used sparingly
- generous spacing and a non-anxious pace

The web should feel premium and composed, not glossy, noisy, mascot-led, or generic SaaS.

## Homepage Structure

### Hero

The hero should:
- keep the sticky navigation pattern
- keep the current text lockup treatment in nav/footer
- use broader system-first copy
- present store badges as secondary proof, not the whole story
- pair the copy with product imagery that communicates multiple parts of the system
- follow the approved mockup’s storytelling structure and composition as closely as practical

Recommended hero message direction:
- primary idea: Conscia is your all-in-one money system
- supporting idea: transactions, reflection, budgets, receipts, insights, and household coordination live in one calm place

The visual treatment should use the app-like cream, lavender, and gold atmosphere rather than the older marketing mood.

The hero media should no longer be a hand-drawn app simulation. It should use a layered collage of real emulator screenshots inside polished device-frame compositions, matching the approved mockup.

### Section Sequence

The homepage should move through the system in this order:

1. Transactions and filters
2. Reflection and purchase assistant
3. Budgets and categories
4. Insights and merchant signals
5. Shared household and settings

This order matches the broader product story:
- capture what happened
- reflect on it
- shape it with budgets/categories
- notice patterns
- coordinate the system with household and settings controls

The storytelling rhythm should follow the approved mockup:
- broad system-first hero
- one product story per section
- alternating screenshot and copy layout
- short supporting bullets beneath each section narrative

### Section Format

Each major section should use:
- one concise copy block
- one strong real screenshot in a polished device frame
- minimal supporting bullets or chips only where they help scanning

The rhythm should stay editorial and breathable. Avoid dense dashboard grids or excessive feature-card repetition.

The approved mockup is the source of truth for section pacing, screenshot prominence, and copy rhythm. Implementation should only make minimal wording or spacing changes when needed to fit the live page cleanly.

## Visual System Changes

### Color and Surface Tuning

The web palette should shift closer to the app:
- background base toward warm ivory instead of bright white
- hero washes toward pale lavender and warm gold
- deep navy retained as the structural anchor
- cyan usage reduced and softened
- shadows kept light and diffused

### Components

The following surfaces should feel closer to app UI:
- hero shell
- feature panels
- phone frames
- chips
- badges
- footer surfaces

They should look like extensions of the app’s cards and hero panels, not separate marketing-only objects.

### Typography

Keep the serif-plus-sans contrast where it supports the app feel:
- serif for emotional/editorial headings
- sans for body, labels, and navigation

The hierarchy should feel calm and deliberate, not loud or startup-polished.

## Product Imagery

The existing simulated Astro screens should be replaced with real emulator screenshots.

Use screenshot-driven marketing media throughout the homepage:
- hero: layered multi-phone collage
- sections: one featured screenshot per story block
- footer CTA area: optional smaller screenshot support only if it improves the composition

Screenshot treatment rules:
- use the real app screenshots as the primary media source
- present them inside polished device-frame compositions like the approved mockup
- do not show them as raw file dumps
- keep crops tight and intentional so key UI details remain readable
- avoid introducing illustrative fake UI where a real screenshot can do the job better

Priority screenshot references from the app:
- transactions with date strip and category rail
- purchase assistant
- budgets overview with donut and category pacing
- insights / merchant signals
- shared household and settings
- receipt scan where useful in the supporting narrative

The screenshot composition and sequencing should follow the approved mockup closely.

## Icon Asset Rules

The new icon should replace icon assets only.

That means:
- update favicon references
- update social preview image references if they currently use the app icon asset
- update any small icon surfaces that intentionally use the app icon image file

That does not mean:
- replacing the nav wordmark with icon-only branding
- replacing the footer lockup with icon-only branding
- introducing a new SVG logo system beyond the icon asset swap already requested

If both full icon and icon-only assets exist, choose the asset that best matches each surface’s current purpose without changing the structural layout.

## Store Link Wiring

Existing App Store / Google Play badges should be wired to production links.

Production URLs:
- iOS: `https://apps.apple.com/app/id6771674327`
- Android: `https://play.google.com/store/apps/details?id=com.getconscia.app.ai`

These links should be used consistently in:
- hero badge area
- footer badge area
- any other existing store badge surfaces already present on the homepage

Do not add new download locations unless they already exist in the current page structure.

## Content Guidance

The copy should emphasize:
- one place for your money system
- clarity without judgment
- reflection as part of the system, not the only story
- product breadth without sounding crowded

The copy should avoid:
- overpromising AI
- sounding like a generic budgeting app
- reverting to mascot-led or overly whimsical framing
- making premium the main homepage message

Premium can appear as one supporting part of the system, especially in settings/subscription imagery, but the homepage should primarily sell the product as a whole.

The approved mockup copy/story is distinctly Conscia and should be treated as the source of truth. During implementation:
- follow its headlines, section order, and overall narrative closely
- keep edits minimal
- only adjust wording when necessary for fit, consistency, or live-page clarity

## Testing And Verification

Implementation should verify:
- homepage content still renders correctly
- existing marketing page tests are updated to the new copy/structure
- store badge links point to the production URLs
- favicon/OG icon references point to the intended new icon assets
- the page still reads well on desktop and mobile widths

## Risks To Watch

- drifting too far into generic SaaS “all-in-one platform” language
- making the page too feature-dense and losing the app’s calm atmosphere
- changing lockup structure when only asset swapping was requested
- using the wrong Android identifier in store URLs
- keeping older simulated screens that no longer match the app enough to feel credible

## Recommended Implementation Boundaries

Make this pass in focused slices:

1. update shared metadata and store links
2. restage hero and homepage section order
3. tune the global visual system to the app atmosphere
4. replace simulated app visuals with screenshot-based media compositions
5. update tests for the revised homepage content

This keeps the work broad in effect but still tractable and reviewable.
