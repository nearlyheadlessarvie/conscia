# Personal Sign-In Design

Date: 2026-06-01

## Goal

Make sign-in feel personal and calm while keeping passkeys as the priority for returning users who have a local device passkey. The screen should still support first-time or "not you" users with the familiar email/password and social sign-in flow.

## Scope

This is an app-side sign-in redesign for `app/lib/screens/onboarding/sign_in_screen.dart` and the local preference/provider code it needs. It does not change passkey registration, Manage Passkeys, or backend passkey APIs.

The implementation should stay surgical:

- Reuse the current sign-in screen, `AuthIntroPanel`, existing fields, social buttons, passkey service, and auth provider.
- Add only the local remembered-identity state needed for the new returning-user flow.
- Keep passkey error handling generic and non-enumerating.

## Local State

The app should remember enough identity to personalize the next sign-in:

- remembered email
- remembered display name
- a local "show initial sign-in" flag set by `Not you?`

The existing passkey preference state remains separate:

- `passkey_registered_emails`
- `passkey_registered_credential_ids`
- `passkey_first_sign_in_enabled`

Tapping `Not you?` must not delete passkey preferences, credential IDs, or remembered identity. It should only set the local flag that makes the screen show the initial email/password state. After a successful sign-in, the app should save the signed-in email and display name, then clear the flag. If the user signs in as a different account, the remembered email and display name should update to that account.

If a display name is not available at the point of sign-in, the app should fall back to a friendly value derived from email until a real display name is known.

## Screen States

### Initial State

Show this state when there is no remembered identity or the "show initial sign-in" flag is set.

- Keep the current email input.
- Keep the current password input, forgot-password link, and primary `Sign In` button.
- Keep Apple and Google sign-in below the `or` divider.
- Do not show the passkey-priority surface.

If passkey sign-in from typed email is still available in the current app, keep it in this state only as a secondary path. It should not drive the remembered-user layout.

### Returning User With Local Passkey

Show this state when:

- there is a remembered email and display name,
- the device reports passkey support,
- the remembered email has a locally saved passkey credential, and
- the "show initial sign-in" flag is not set.

The layout should feel like the approved calm mockup:

- Keep the warm `Welcome back` intro panel.
- Under the panel, show a left-aligned identity block:
  - `Welcome back,`
  - display name
  - `Not you?` as a small text action near the identity
- Center the passkey action below the identity:
  - use the current passkey icon container style, with narrower padding than the old passkey-first block
  - show the remembered email as supporting text near the passkey action
  - tapping the centered passkey action signs in with the remembered email and immediately available credentials
- Center `Sign in with password` as a text-only action below the passkey action.
- Hide the password input, forgot-password link, and primary `Sign In` button until the user chooses password mode.
- Keep social sign-in below the `or` divider so the screen still reads as an auth screen.

### Returning User Password Mode

Show this state when the remembered user taps `Sign in with password`, or when the remembered user does not have a local passkey.

- Keep the same personal intro and identity block.
- Show password input, forgot-password link, and primary `Sign In` button.
- Do not make the email editable in this returning-user state.
- If a local passkey is available, show a centered text-only passkey action below the primary button:
  - passkey icon
  - `Sign in with passkey`
- Keep Apple and Google sign-in below the `or` divider.

### Not You

Tapping `Not you?` should switch to the initial state by setting the local flag. It should not clear:

- remembered email
- remembered display name
- saved passkey emails
- saved credential IDs

A later successful sign-in clears the flag and updates remembered identity to the signed-in account.

## External Passkeys

The current app passkey sign-in API requires an email before starting authentication. The recent app-side change allows typed-email passkey sign-in to request external credentials where platform support allows it, but Android external passkeys appear to have a separate client-side issue.

This redesign should preserve existing typed-email passkey behavior where it already exists, but it should not try to solve username-less discoverable passkeys or the Android external-passkey issue. Those should be handled as separate tasks.

## Error Handling

Passkey failures should remain generic and non-enumerating:

- keep the current generic passkey sign-in failure copy
- do not reveal whether an email exists
- do not show "no passkey found for this account on this device" for typed-email sign-in

If a remembered local passkey is stale or unavailable, the app may remove that local passkey preference for the email and fall back to password mode. It must not clear remembered identity unless the user changes accounts through the initial sign-in flow.

## Testing

Add focused tests around the new state transitions:

- initial state shows email/password/social sign-in when no remembered identity exists
- `Not you?` flag shows initial state without deleting passkey preferences
- successful password sign-in stores remembered email/display name and clears the flag
- successful social or external sign-in updates remembered identity when a display name is available
- returning user with a local passkey sees centered passkey priority and `Sign in with password`
- password mode hides email editing, shows password controls, and keeps a text-only passkey action when available
- stale local passkey falls back without clearing remembered identity
- typed-email passkey errors remain generic

Provider or preference tests should cover the remembered-identity state separately from existing passkey preferences.

## Out Of Scope

- Changing Manage Passkeys behavior.
- Changing passkey registration behavior.
- Adding username-less discoverable passkey APIs.
- Fixing Android external passkey behavior.
- Clearing passkey preferences from `Not you?`.
- Broad auth-provider refactors unrelated to saving or reading remembered sign-in identity.
