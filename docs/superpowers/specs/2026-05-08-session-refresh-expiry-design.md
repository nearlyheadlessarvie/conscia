# Session Refresh and Expiry Design

## Goal

Keep users signed in silently when refresh is still possible, and replace today's abrupt logout behavior with a clear session-expired experience when it is not.

## Current Problems

- The app stores `access_token` and `refresh_token`, but never uses refresh.
- Any `401` response immediately clears secure storage and logs the user out.
- Users get no warning, retry path, or explanation when their session ends.
- The backend does not currently expose a real `/api/v1/auth/refresh` endpoint.

## Proposed Behavior

### Silent refresh first

- When a protected API call returns `401`, the app should attempt token refresh once.
- If refresh succeeds:
  - store the new tokens
  - retry the failed request once
  - keep the user in place with no visible interruption

### Session-expired fallback

- If refresh fails, the app should stop treating the user as authenticated.
- Instead of silently dumping the user back to onboarding, the app should show a dedicated `Session expired` surface.
- That surface should explain that the session ended and prompt the user to sign in again.

### No proactive "extend session" prompt in v1

- As long as refresh tokens are still valid, the app should refresh silently.
- We do not need an "extend session?" prompt in this slice.
- Pre-expiry prompts can be added later if product wants explicit session controls.

## Backend Design

### New endpoint

- Add `POST /api/v1/auth/refresh`

Request:

```json
{
  "refreshToken": "..."
}
```

Response on success:

```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "userId": "..."
}
```

Response on failure:

- `401` with a stable auth error body

### Auth service contract

- Extend `IAuthService` with a refresh method.
- Mock auth should support refresh for local/dev.
- Cognito-backed auth can later map this same interface to Cognito refresh.

### Mock refresh rules

- Accept the mock refresh token format already issued by `MockAuthService`.
- Resolve the user from the token payload.
- Issue a fresh signed JWT access token and a fresh refresh token.
- Reject malformed or unknown refresh tokens with `401`.

## App Design

### Dio refresh coordinator

- Replace the current `401 => logout immediately` logic in `dio_client.dart`.
- Add a refresh coordinator with these rules:
  - only one refresh request runs at a time
  - concurrent `401` requests wait for the same refresh attempt
  - each original request is retried at most once
  - if refresh fails, do not retry endlessly

### Auth state

- Add an explicit session-expired state to `AuthState`.
- `authProvider.logout()` remains a user-driven sign-out.
- Session expiry should use a separate state transition so the UI can show the correct message.

### Session-expired UX

- Add a dedicated full-screen `Session expired` route/surface.
- It should:
  - explain the session expired
  - preserve a clear sign-in action
  - avoid dumping the user into onboarding copy that implies they are new

### Router behavior

- If auth transitions to session-expired, route to the session-expired surface.
- If the user signs in again successfully, normal routing rules resume.

## Scope Decisions

Included:

- backend refresh endpoint
- client silent refresh with retry-once behavior
- session-expired UI/screen
- router integration
- mock auth refresh support

Not included:

- biometrics
- inactivity timers
- passkeys / WebAuthn
- proactive pre-expiry prompts

## Error Handling

- Refresh request fails with `401`: move to session-expired state.
- Refresh request fails due to network error:
  - do not instantly purge tokens
  - allow the original request failure to surface normally if appropriate
  - only treat confirmed auth invalidation as session expiry
- Retry loops must be prevented by marking retried requests.

## Testing

Backend:

- refresh endpoint returns new tokens for a valid mock refresh token
- refresh endpoint rejects invalid refresh tokens

App:

- `401` triggers refresh once and retries original request
- concurrent `401`s share one refresh flow
- failed refresh routes to session-expired screen
- user-driven logout still clears session normally

