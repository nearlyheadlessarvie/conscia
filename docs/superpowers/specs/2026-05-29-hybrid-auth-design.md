# Hybrid Auth Design

## Goal

Restore Conscia's in-app email authentication while keeping Cognito as the token authority and social OAuth broker.

## Scope

- Sign-in, sign-up, email verification, and password reset are in-app flows.
- Google and Apple sign-in continue through Cognito hosted OAuth with provider handoff.
- Passkey-first sign-in is available only for accounts that successfully registered a passkey on this device.
- Cognito managed-login styling is reduced because the hosted surface is no longer used for email/password auth.
- Social auth cancellation is quiet; aborting Google or Apple sign-in does not show an inline error.

## Email Auth

The mobile app restores the pre-managed-login email/password sign-in and sign-up screens. Sign-in collects email and password and calls the API `auth/login` endpoint. Sign-up collects email, password, and confirmation password, then calls `auth/register`. Email verification continues to use the existing in-app code screen and logs the user in with the pending credentials after a successful confirmation.

## Password Reset

Password reset is a new in-app code flow:

1. The user taps "Forgot password?" from sign-in.
2. The app asks for an email address and calls a new API endpoint that starts Cognito password recovery.
3. The user enters the emailed code and a new password.
4. The API confirms the reset with Cognito.
5. The app signs in automatically with the reset email and new password.

The reset screen should use the existing auth visual language and password validation rules. Reset cancellation returns to sign-in without changing auth state.

## Social Auth

Google and Apple buttons remain on the sign-in screen. They call the existing `AuthNotifier.signInWithGoogle` and `AuthNotifier.signInWithApple` methods, which open Cognito hosted OAuth using the provider-specific `identity_provider` parameter. Cognito remains responsible for issuing JWTs for these sessions.

If the native auth sheet or hosted provider flow is cancelled by the user, the app returns to the sign-in screen without showing an error notice. Other managed-login failures still render as inline notices.

## Passkey-First Sign-In

When a passkey is registered in Settings, the app stores that email in a local passkey account registry. The registry is device-local and contains only accounts that completed passkey registration on this device.

If passkey-first preference is enabled and the registry has accounts, sign-in starts in passkey mode:

- One registered account: show one-tap passkey sign-in for that email.
- Multiple registered accounts: show an account picker and sign in with the selected email.
- No registered accounts: show the normal email/password screen.

Passkey-first always includes a "Sign in with email" escape hatch. The Settings screen exposes a local preference to enable or disable passkey-first once passkeys are available for the current session.

## Hosted Login Failure Investigation

The mobile service already builds the expected Cognito authorize URL with PKCE, provider handoff, custom-scheme redirect, and token exchange. The live "Something went wrong" page is most likely caused by Cognito hosted IdP configuration or deploy-time provider secret/client mismatch, not local URL construction. Infra tests should continue to assert that Google and Apple identity providers are attached to the app client and receive deploy-time secrets.

## Infra Cleanup

Keep the Cognito domain, app client OAuth settings, identity providers, and terms links needed by Google/Apple hosted OAuth. Remove custom managed-login branding assets and style settings that were added for the full Cognito managed sign-in/sign-up experience.

## Verification

- Flutter widget tests cover restored sign-in, sign-up, password reset navigation, quiet social cancellation, and passkey-first account selection.
- Flutter provider/service tests cover password reset API calls and passkey account registry behavior.
- API endpoint/unit tests cover forgot-password and confirm-reset request validation and Cognito service calls.
- Infra tests cover that managed-login branding is no longer emitted while social IdP configuration remains.
