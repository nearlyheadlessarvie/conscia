# Platform Setup — Google & Apple Sign-In

## iOS

### Sign in with Apple
1. Open your project in Xcode.
2. Select your target → **Signing & Capabilities** → click **+ Capability** → add **Sign in with Apple**.
3. Ensure the capability is enabled in your Apple Developer portal under **Certificates, Identifiers & Profiles** → your App ID.

### Google Sign-In
1. Go to the [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
2. Create an **OAuth 2.0 Client ID** of type **iOS**.
3. Enter your app's **Bundle ID** (e.g. `com.getconscia.app.ai`).
4. Download the `GoogleService-Info.plist` and add it to `ios/Runner/` in Xcode.
5. Add the **reversed client ID** as a URL scheme:
   - Open `ios/Runner/Info.plist` and add a `CFBundleURLTypes` entry with the reversed client ID from the plist (e.g. `com.googleusercontent.apps.YOUR_CLIENT_ID`).

## Android

### Google Sign-In
1. Go to the [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
2. Create an **OAuth 2.0 Client ID** of type **Android**.
3. Enter your app's **package name** (e.g. `com.getconscia.app.ai`) and the **SHA-1 fingerprint** of your signing key:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
   ```
4. Download the `google-services.json` and place it in `android/app/`.
5. Ensure `android/build.gradle` applies the Google Services plugin:
   ```gradle
   classpath 'com.google.gms:google-services:4.4.0'
   ```
6. Ensure `android/app/build.gradle` applies the plugin:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### Sign in with Apple (Android)
Apple Sign-In on Android requires a web-based redirect flow. This is handled automatically by the `sign_in_with_apple` package but requires a **Service ID** configured in the Apple Developer portal with a valid redirect URI pointing to your backend's callback endpoint.
