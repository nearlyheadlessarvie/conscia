# App Icon Setup

## Steps to generate platform icons

1. Copy `conscia_icon_1024.png` from the project root's `assets/` folder into this directory as `app_icon.png`:
   ```
   cp ../../assets/conscia_icon_1024.png app/assets/images/app_icon.png
   ```

2. For Android adaptive icons, create a foreground-only version of the icon (the icon artwork without any background color) and save it as `app_icon_foreground.png` in this same directory. The adaptive icon background color (#1A237E navy) is configured separately in `flutter_launcher_icons.yaml`.

3. Run the icon generator from the `app/` directory:
   ```
   dart run flutter_launcher_icons
   ```

This will generate all required icon sizes for Android and iOS platforms.
