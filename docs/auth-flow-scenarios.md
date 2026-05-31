# Auth Flow Scenarios

This note documents the expected behavior for in-app email auth, social sign-in, and the pre-sign-up account-linking trigger. Keep this in sync when changing auth code.

## Goals

- In-app email sign-in, sign-up, verification, password reset, and password change stay inside Conscia.
- Social sign-in is a sign-in path, not a separate sign-up screen.
- The identity provider remains the token authority for access and refresh tokens.
- Conscia local users and identities are bootstrapped from verified identity-provider claims.
- Users should not end up with duplicate accounts for the same verified email.

## Email Sign-Up

| Scenario | Expected behavior | Where handled |
| --- | --- | --- |
| New email/password user signs up | Create the identity-provider user, send verification email, return `requiresConfirmation`. | `POST /api/auth/register`, auth service |
| User confirms email with code | Confirm the provider user, mark local user email confirmed when the user next authenticates, then allow sign-in. | `POST /api/auth/confirm`, current-user bootstrap |
| Email already exists as a local email/password account | Return a sign-up error. User should sign in or reset password. | identity provider, auth service |
| Email already exists only as a social/external identity | Reject email sign-up with a message to use Google or Apple first. This avoids creating a second account for the same email. | pre-sign-up trigger |
| Email already exists as a linked local anchor plus social identity | Treat as an existing account. User signs in with social or adds/changes password later from Security settings. | identity provider, app Security settings |
| Unverified or missing email during sign-up | Reject or require confirmation before local account bootstrap. | identity provider, auth service |

## Email Sign-In

| Scenario | Expected behavior | Where handled |
| --- | --- | --- |
| Confirmed email/password user signs in | Return access/refresh tokens and bridge to the dashboard only after authenticated Dio can use the access token. | `POST /api/auth/login`, app auth provider |
| Wrong password or unknown email | Return generic invalid credentials message. | `POST /api/auth/login` |
| Email user is unconfirmed | Return `requiresConfirmation`; app routes to the verification screen. | `POST /api/auth/login`, app auth provider |
| Temporary-password user signs in | Return `requiresPasswordChange`; app opens the change-required password flow using the provider session, not the normal authenticated password endpoint. | `POST /api/auth/login`, `POST /api/auth/password/change-required` |
| Signed-in user adds password for a social-only account | Require a valid signed-in session and set a permanent password for the current user. | `POST /api/auth/password`, Security settings |
| Signed-in password user changes password | Require current password, valid signed-in session, and a new password matching the shared password policy. | `POST /api/auth/password`, Security settings |
| Password reset requested | Send reset code if the provider can handle the email, then confirm with code and new password. | `POST /api/auth/password-reset/start`, `POST /api/auth/password-reset/confirm` |

## Social Sign-In

| Scenario | Expected behavior | Where handled |
| --- | --- | --- |
| Social sign-in with email matching an existing local account | Link the social provider identity to the local user, then complete sign-in. | pre-sign-up trigger |
| First social sign-in with a new verified email | Create a suppressed local anchor user, set a hidden permanent password so the provider can link to it, link the social identity, then complete sign-in. | pre-sign-up trigger |
| Social sign-in after the provider is already linked | Complete sign-in normally and return tokens. | identity provider |
| Google and Apple use the same verified email | Both providers should link to the same local anchor user instead of creating two external-only users. | pre-sign-up trigger |
| Social provider does not return a verified email | Do not link automatically. Sign-in should fail rather than risk account takeover. | pre-sign-up trigger |
| Unsupported external provider reaches the trigger | Ignore linking and let the provider reject or continue according to its own config. | pre-sign-up trigger |
| User cancels social sign-in | Return to sign-in quietly, without an inline error. | app auth provider |
| Social callback succeeds but `/users/me` has no email claim | Resolve from the local user/identity store first. Only call the userinfo endpoint if the first login has no local identity and no email claim. | current-user bootstrap |

## Current-User Bootstrap

| Scenario | Expected behavior | Where handled |
| --- | --- | --- |
| Authenticated token maps to an existing local user identity | Use that local user. | current-user bootstrap middleware |
| Authenticated token has provider subject but no local identity | Create or attach a local identity using verified email from claims or userinfo. | current-user bootstrap middleware |
| Authenticated token has no email and local identity cannot resolve it | Return a clear client error for flows that require email, such as family invites. | current-user bootstrap middleware and endpoint validation |
| Local user exists by email but identity is missing | Attach the missing provider identity to the existing local user. | current-user bootstrap middleware |
| Local user exists by provider identity but email changed upstream | Prefer the stable provider identity for user resolution; email updates should be handled deliberately, not by creating a new user. | current-user bootstrap middleware |

## Passkey Notes

| Scenario | Expected behavior | Where handled |
| --- | --- | --- |
| User registers a passkey successfully | Store the account as passkey-capable on this device and enable passkey-first if requested. | Security settings, passkey service |
| Registration start returns excluded credentials | Tell the user a passkey may already be saved and explain how to remove the device-side credential. | app passkey service |
| User removes an account passkey in Conscia | Delete the provider-side passkey credential and refresh the list. | `DELETE /api/auth/passkeys/{credentialId}` |
| User forgets passkeys for this device | Delete only the account-side passkey credential id that was registered from this device, then clear the local passkey-first preference. Do not delete other account passkeys because other devices may still rely on them. The OS password manager passkey still needs manual removal because mobile platforms do not expose silent passkey deletion to apps. | Security settings |

## Known Bad Data Handling

- During UAT, duplicate external-only users can be cleaned manually.
- After cleanup, the expected steady state is one local anchor user per verified email, with zero or more linked provider identities.
- If duplicate external users appear again after cleanup, treat it as a pre-sign-up linker regression.
