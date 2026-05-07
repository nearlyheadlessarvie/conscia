# App Icon Setup

## Source of truth

- `app_icon.svg` is the current Phase 4 brand source.
- The mark follows the simplified Conscia direction: devil on the left, angel on the right, circular split-balance silhouette, and a darker premium red against navy.

## Steps to generate platform icons

1. Export `app_icon.svg` to a 1024x1024 PNG and save it as `app_icon.png` in this folder.
2. Export a foreground-only version of the same mark and save it as `app_icon_foreground.png`.
   This is used for Android adaptive icons on top of the configured navy background (`#1A237E`).
3. Run the icon generator from `app/`:
   ```
   dart run flutter_launcher_icons
   ```

This will regenerate Android and iOS launcher assets from the latest mark.
