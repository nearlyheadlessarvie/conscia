# Personal Sign-In Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved personal returning-user sign-in flow where local passkeys are prioritized, `Not you?` returns to the initial form without clearing saved passkeys, and password/social sign-in remain available.

**Architecture:** Add one small remembered sign-in preference provider backed by `SharedPreferences`, then have auth success paths persist remembered identity through that provider's helper functions. The sign-in screen reads remembered identity plus existing passkey preferences to choose between initial email/password, returning passkey-priority, and returning password modes.

**Tech Stack:** Flutter, Riverpod, SharedPreferences, existing Conscia auth/passkey providers, Flutter widget tests.

---

## File Structure

- Create `app/lib/providers/sign_in_preference_provider.dart`: owns remembered email, remembered display name, and the local `Not you?` flag. It also exposes helper functions that non-Riverpod auth code can use to persist remembered identity.
- Create `app/test/providers/sign_in_preference_provider_test.dart`: covers preference load/store behavior independently from passkey preferences.
- Modify `app/lib/core/routing/app_router.dart`: keep the existing `saveLastEmail` and `getLastEmail` API, but make them use the shared remembered-email key from the new provider.
- Modify `app/lib/providers/auth_provider.dart`: after successful auth, persist remembered identity and clear the `Not you?` flag. Parse `email`, `name`, and `given_name` claims from ID/access tokens where available.
- Modify `app/test/providers/auth_provider_test.dart`: prove successful auth stores remembered identity and that pending auth challenges do not.
- Modify `app/lib/screens/onboarding/sign_in_screen.dart`: replace the old passkey-first account chooser with the personal returning-user states.
- Modify `app/test/screens/onboarding/sign_in_screen_test.dart`: replace old passkey-first expectations with the new returning-user behavior.

## Task 1: Remembered Sign-In Preference Provider

**Files:**
- Create: `app/lib/providers/sign_in_preference_provider.dart`
- Create: `app/test/providers/sign_in_preference_provider_test.dart`

- [ ] **Step 1: Write the failing provider tests**

Create `app/test/providers/sign_in_preference_provider_test.dart`:

```dart
import 'package:conscia_app/providers/sign_in_preference_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('remembered sign-in preference loads normalized identity', () async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: ' Story-Demo@Example.COM ',
      rememberedSignInDisplayNamePreferenceKey: ' Story Demo ',
      showInitialSignInPreferenceKey: false,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    final preference = container.read(rememberedSignInPreferenceProvider);

    expect(preference.email, 'story-demo@example.com');
    expect(preference.displayName, 'Story Demo');
    expect(preference.hasRememberedIdentity, isTrue);
    expect(preference.showInitialSignIn, isFalse);
  });

  test('remembered sign-in preference stores identity and clears initial flag',
      () async {
    SharedPreferences.setMockInitialValues({
      showInitialSignInPreferenceKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container.read(rememberedSignInPreferenceProvider.notifier).remember(
          email: ' Story-Demo@Example.COM ',
          displayName: ' Story Demo ',
        );

    final preference = container.read(rememberedSignInPreferenceProvider);
    expect(preference.email, 'story-demo@example.com');
    expect(preference.displayName, 'Story Demo');
    expect(preference.showInitialSignIn, isFalse);
    expect(
      prefs.getString(rememberedSignInEmailPreferenceKey),
      'story-demo@example.com',
    );
    expect(
      prefs.getString(rememberedSignInDisplayNamePreferenceKey),
      'Story Demo',
    );
    expect(prefs.getBool(showInitialSignInPreferenceKey), isFalse);
  });

  test('not you shows initial sign-in without clearing identity', () async {
    SharedPreferences.setMockInitialValues({
      rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
      rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
      showInitialSignInPreferenceKey: false,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await container
        .read(rememberedSignInPreferenceProvider.notifier)
        .showInitialSignIn();

    final preference = container.read(rememberedSignInPreferenceProvider);
    expect(preference.email, 'story-demo@example.com');
    expect(preference.displayName, 'Story Demo');
    expect(preference.hasRememberedIdentity, isTrue);
    expect(preference.showInitialSignIn, isTrue);
    expect(
      prefs.getString(rememberedSignInEmailPreferenceKey),
      'story-demo@example.com',
    );
    expect(
      prefs.getString(rememberedSignInDisplayNamePreferenceKey),
      'Story Demo',
    );
  });
}
```

- [ ] **Step 2: Run the provider tests to verify they fail**

Run from `app`:

```powershell
flutter test test/providers/sign_in_preference_provider_test.dart
```

Expected: FAIL because `sign_in_preference_provider.dart` does not exist.

- [ ] **Step 3: Add the provider implementation**

Create `app/lib/providers/sign_in_preference_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'usage_provider.dart';

const rememberedSignInEmailPreferenceKey = 'last_login_email';
const rememberedSignInDisplayNamePreferenceKey =
    'remembered_sign_in_display_name';
const showInitialSignInPreferenceKey = 'show_initial_sign_in';

class RememberedSignInPreference {
  const RememberedSignInPreference({
    required this.email,
    required this.displayName,
    required this.showInitialSignIn,
  });

  final String? email;
  final String? displayName;
  final bool showInitialSignIn;

  bool get hasRememberedIdentity =>
      email != null && email!.trim().isNotEmpty;

  String get displayNameOrEmail {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return rememberedDisplayNameFromEmail(email ?? '');
  }

  RememberedSignInPreference copyWith({
    String? email,
    String? displayName,
    bool? showInitialSignIn,
  }) {
    return RememberedSignInPreference(
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      showInitialSignIn: showInitialSignIn ?? this.showInitialSignIn,
    );
  }
}

class RememberedSignInPreferenceNotifier
    extends StateNotifier<RememberedSignInPreference> {
  RememberedSignInPreferenceNotifier(this._prefs)
      : super(_loadRememberedSignIn(_prefs));

  final SharedPreferences _prefs;

  Future<void> remember({
    required String email,
    String? displayName,
  }) async {
    final next = await persistRememberedSignInIdentity(
      _prefs,
      email: email,
      displayName: displayName,
    );
    state = next;
  }

  Future<void> showInitialSignIn() async {
    await _prefs.setBool(showInitialSignInPreferenceKey, true);
    state = state.copyWith(showInitialSignIn: true);
  }
}

final rememberedSignInPreferenceProvider = StateNotifierProvider<
    RememberedSignInPreferenceNotifier,
    RememberedSignInPreference>((ref) {
  return RememberedSignInPreferenceNotifier(
    ref.watch(sharedPreferencesProvider),
  );
});

Future<RememberedSignInPreference> persistRememberedSignInIdentity(
  SharedPreferences prefs, {
  required String email,
  String? displayName,
}) async {
  final normalizedEmail = _normalizeEmail(email);
  if (normalizedEmail == null) {
    return _loadRememberedSignIn(prefs);
  }

  final normalizedDisplayName = _normalizeText(displayName) ??
      rememberedDisplayNameFromEmail(normalizedEmail);

  await prefs.setString(rememberedSignInEmailPreferenceKey, normalizedEmail);
  await prefs.setString(
    rememberedSignInDisplayNamePreferenceKey,
    normalizedDisplayName,
  );
  await prefs.setBool(showInitialSignInPreferenceKey, false);

  return RememberedSignInPreference(
    email: normalizedEmail,
    displayName: normalizedDisplayName,
    showInitialSignIn: false,
  );
}

RememberedSignInPreference _loadRememberedSignIn(SharedPreferences prefs) {
  return RememberedSignInPreference(
    email: _normalizeEmail(prefs.getString(rememberedSignInEmailPreferenceKey)),
    displayName:
        _normalizeText(prefs.getString(rememberedSignInDisplayNamePreferenceKey)),
    showInitialSignIn:
        prefs.getBool(showInitialSignInPreferenceKey) ?? false,
  );
}

String rememberedDisplayNameFromEmail(String email) {
  final normalized = _normalizeEmail(email);
  if (normalized == null) return 'there';

  final localPart = normalized.split('@').first;
  final words = localPart
      .split(RegExp(r'[._+\-]+'))
      .where((part) => part.trim().isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return normalized;

  return words
      .map((word) => word.length == 1
          ? word.toUpperCase()
          : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String? _normalizeEmail(String? email) {
  final trimmed = email?.trim().toLowerCase();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String? _normalizeText(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
```

- [ ] **Step 4: Run the provider tests to verify they pass**

Run from `app`:

```powershell
flutter test test/providers/sign_in_preference_provider_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit the provider**

Run from repo root:

```powershell
git status -sb
git add -- app/lib/providers/sign_in_preference_provider.dart app/test/providers/sign_in_preference_provider_test.dart
git commit -m "feat(app): remember sign-in identity"
```

## Task 2: Persist Remembered Identity After Auth Success

**Files:**
- Modify: `app/lib/core/routing/app_router.dart`
- Modify: `app/lib/providers/auth_provider.dart`
- Modify: `app/test/providers/auth_provider_test.dart`

- [ ] **Step 1: Write failing auth-provider tests**

In `app/test/providers/auth_provider_test.dart`, import the new provider:

```dart
import 'package:conscia_app/providers/sign_in_preference_provider.dart';
```

Replace the existing `_fakeJwt` helper with a version that accepts extra claims:

```dart
String _fakeJwt({
  required DateTime expiresAt,
  Map<String, Object?> claims = const {},
}) {
  final header = base64Url.encode(utf8.encode('{"alg":"none","typ":"JWT"}'));
  final payload = base64Url.encode(
    utf8.encode(
      jsonEncode({
        'sub': 'user-1',
        'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
        ...claims,
      }),
    ),
  );
  return '$header.$payload.signature';
}
```

Add these tests near the successful login tests:

```dart
test('login stores remembered identity and clears initial sign-in flag',
    () async {
  SharedPreferences.setMockInitialValues({
    showInitialSignInPreferenceKey: true,
  });
  final prefs = await SharedPreferences.getInstance();
  final service = _FakeAuthService(
    AuthTokens(
      accessToken: 'access.token',
      idToken: _fakeJwt(
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        claims: {
          'email': 'Story-Demo@Example.COM',
          'name': 'Story Demo',
        },
      ),
      refreshToken: 'refresh-token',
      userId: 'user-1',
    ),
  );
  final notifier = AuthNotifier(service, _FakeSecureStorage());

  await notifier.login('Story-Demo@Example.COM', 'SecureP@ss123');

  expect(
    prefs.getString(rememberedSignInEmailPreferenceKey),
    'story-demo@example.com',
  );
  expect(
    prefs.getString(rememberedSignInDisplayNamePreferenceKey),
    'Story Demo',
  );
  expect(prefs.getBool(showInitialSignInPreferenceKey), isFalse);
});

test('login falls back to email-derived remembered display name', () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final service = _FakeAuthService(
    const AuthTokens(
      accessToken: 'access.token',
      refreshToken: 'refresh-token',
      userId: 'user-1',
    ),
  );
  final notifier = AuthNotifier(service, _FakeSecureStorage());

  await notifier.login('story-demo@example.com', 'SecureP@ss123');

  expect(
    prefs.getString(rememberedSignInDisplayNamePreferenceKey),
    'Story Demo',
  );
});

test('login requiring confirmation does not store remembered identity',
    () async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final service = _FakeAuthService(
    const AuthTokens(
      accessToken: 'verified.access.token',
      refreshToken: 'verified-refresh-token',
      userId: 'verified-user',
    ),
  )..loginError = const AuthConfirmationRequiredException(
      email: 'new@example.com',
    );
  final notifier = AuthNotifier(service, _FakeSecureStorage());

  await notifier.login('new@example.com', 'SecureP@ss123');

  expect(prefs.getString(rememberedSignInDisplayNamePreferenceKey), isNull);
  expect(prefs.getBool(showInitialSignInPreferenceKey), isNull);
});
```

- [ ] **Step 2: Run the auth-provider tests to verify they fail**

Run from `app`:

```powershell
flutter test test/providers/auth_provider_test.dart
```

Expected: FAIL because auth success paths do not write remembered display name or clear `show_initial_sign_in`.

- [ ] **Step 3: Point routing last-email helpers at the shared key**

In `app/lib/core/routing/app_router.dart`, import the provider:

```dart
import '../../providers/sign_in_preference_provider.dart';
```

Remove the private `_lastEmailKey` constant, then update the helpers:

```dart
Future<void> saveLastEmail(String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(rememberedSignInEmailPreferenceKey, email.trim());
}

Future<String?> getLastEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(rememberedSignInEmailPreferenceKey);
}
```

- [ ] **Step 4: Persist remembered identity in auth success paths**

In `app/lib/providers/auth_provider.dart`, add the import:

```dart
import 'sign_in_preference_provider.dart';
```

Update successful auth calls so they pass the email they know:

```dart
final tokens = await _authService.login(email, password);
await _setAuthenticated(tokens, rememberedEmail: email);
```

Use the same pattern for:

```dart
await _setAuthenticated(tokens, rememberedEmail: email);
await _setAuthenticated(tokens, rememberedEmail: normalizedEmail);
await _setAuthenticated(tokens, rememberedEmail: emailHint);
await _setAuthenticated(tokens, rememberedEmail: email?.trim());
await _setAuthenticated(tokens);
```

The no-email form is for managed social auth where the ID token should provide an email claim.

Replace `_setAuthenticated` with this signature and body:

```dart
Future<void> _setAuthenticated(
  AuthTokens tokens, {
  String? rememberedEmail,
}) async {
  await _persistTokens(tokens);
  await _rememberSignedInIdentity(tokens, email: rememberedEmail);
  await clearOnboardingComplete();
  await _clearPendingConfirmation();
  state = state.copyWith(
    status: AuthStatus.authenticated,
    accessToken: tokens.accessToken,
    idToken: tokens.idToken,
    refreshToken: tokens.refreshToken,
    userId: tokens.userId,
    pendingEmail: null,
    passwordChangeSession: null,
    isLoading: false,
    isRestoringSession: false,
    error: null,
    wasExplicitLogout: false,
  );
}
```

Add these helpers inside `AuthNotifier`:

```dart
Future<void> _rememberSignedInIdentity(
  AuthTokens tokens, {
  String? email,
}) async {
  final claims = _tryDecodeJwtPayload(tokens.idToken ?? '') ??
      _tryDecodeJwtPayload(tokens.accessToken);
  final normalizedEmail = _normalizeEmail(email) ??
      _normalizeEmail(_stringClaim(claims, 'email')) ??
      _normalizeEmail(_stringClaim(claims, 'cognito:username'));
  if (normalizedEmail == null) return;

  final prefs = await SharedPreferences.getInstance();
  await persistRememberedSignInIdentity(
    prefs,
    email: normalizedEmail,
    displayName: _displayNameFromClaims(claims),
  );
}

static String? _displayNameFromClaims(Map<String, dynamic>? claims) {
  final name = _stringClaim(claims, 'name');
  if (name != null) return name;

  final givenName = _stringClaim(claims, 'given_name');
  final familyName = _stringClaim(claims, 'family_name');
  final combined = [
    if (givenName != null) givenName,
    if (familyName != null) familyName,
  ].join(' ').trim();
  return combined.isEmpty ? null : combined;
}

static String? _stringClaim(Map<String, dynamic>? claims, String key) {
  final value = claims?[key];
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
```

- [ ] **Step 5: Run the auth-provider tests to verify they pass**

Run from `app`:

```powershell
flutter test test/providers/auth_provider_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit auth persistence**

Run from repo root:

```powershell
git status -sb
git add -- app/lib/core/routing/app_router.dart app/lib/providers/auth_provider.dart app/test/providers/auth_provider_test.dart
git commit -m "feat(app): persist remembered sign-in identity"
```

## Task 3: Personal Returning-User Sign-In UI

**Files:**
- Modify: `app/lib/screens/onboarding/sign_in_screen.dart`
- Modify: `app/test/screens/onboarding/sign_in_screen_test.dart`

- [ ] **Step 1: Write failing widget tests for returning-user states**

In `app/test/screens/onboarding/sign_in_screen_test.dart`, add this import:

```dart
import 'package:conscia_app/providers/sign_in_preference_provider.dart';
```

Add these tests near the existing passkey-first tests. The old tests named `passkey-first sign in uses the saved single account`, `passkey-first fallback can return from email sign in`, and `passkey-first sign in prompts for multiple saved accounts` should be removed or rewritten by these tests.

```dart
testWidgets('returning user with local passkey sees passkey priority',
    (tester) async {
  SharedPreferences.setMockInitialValues({
    rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
    rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
    passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
  });
  final authNotifier = _RecordingAuthNotifier();
  final passkeyService = _RecordingPasskeyService();

  await _pumpSignInScreen(
    tester,
    authNotifier: authNotifier,
    passkeysAvailable: true,
    passkeyService: passkeyService,
  );

  expect(find.text('Welcome back,'), findsOneWidget);
  expect(find.text('Story Demo'), findsOneWidget);
  expect(find.text('Not you?'), findsOneWidget);
  expect(find.text('story-demo@example.com'), findsOneWidget);
  expect(find.byKey(const ValueKey('saved-passkey-primary')), findsOneWidget);
  expect(find.text('Sign in with password'), findsOneWidget);
  expect(find.byType(TextField), findsNothing);
  expect(find.text('Sign in with Apple'), findsOneWidget);

  await tester.tap(find.byKey(const ValueKey('saved-passkey-primary')));
  await tester.pump();

  expect(passkeyService.lastSignInEmail, 'story-demo@example.com');
  expect(passkeyService.lastPreferImmediatelyAvailableCredentials, isTrue);
  expect(authNotifier.completedExternalEmail, 'story-demo@example.com');
});

testWidgets('returning user password mode signs in with remembered email',
    (tester) async {
  SharedPreferences.setMockInitialValues({
    rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
    rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
    passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
  });
  final authNotifier = _RecordingAuthNotifier();

  await _pumpSignInScreen(
    tester,
    authNotifier: authNotifier,
    passkeysAvailable: true,
    passkeyService: _RecordingPasskeyService(),
  );

  await tester.tap(find.text('Sign in with password'));
  await tester.pumpAndSettle();

  expect(find.text('Story Demo'), findsOneWidget);
  expect(find.byType(TextField), findsOneWidget);
  expect(find.text('Forgot password?'), findsOneWidget);
  expect(find.widgetWithText(FilledButton, 'Sign In'), findsOneWidget);
  expect(find.text('Sign in with passkey'), findsOneWidget);

  await tester.enterText(find.byType(TextField), 'SecurePass123');
  await tester.tap(find.widgetWithText(FilledButton, 'Sign In'));
  await tester.pump();

  expect(authNotifier.lastLoginEmail, 'story-demo@example.com');
  expect(authNotifier.lastLoginPassword, 'SecurePass123');
});

testWidgets('not you returns to initial sign in without clearing passkeys',
    (tester) async {
  SharedPreferences.setMockInitialValues({
    rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
    rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
    passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
    passkeyFirstSignInEnabledPreferenceKey: true,
  });
  final prefs = await SharedPreferences.getInstance();

  await _pumpSignInScreen(
    tester,
    authNotifier: _RecordingAuthNotifier(),
    passkeysAvailable: true,
    passkeyService: _RecordingPasskeyService(),
  );

  await tester.tap(find.text('Not you?'));
  await tester.pumpAndSettle();

  expect(find.byType(TextField), findsNWidgets(2));
  expect(find.text('Password'), findsOneWidget);
  expect(find.text('Sign In'), findsOneWidget);
  expect(prefs.getBool(showInitialSignInPreferenceKey), isTrue);
  expect(
    prefs.getString(rememberedSignInEmailPreferenceKey),
    'story-demo@example.com',
  );
  expect(
    prefs.getStringList(passkeyRegisteredEmailsPreferenceKey),
    ['story-demo@example.com'],
  );
});

testWidgets('initial sign in stays visible when not you flag is set',
    (tester) async {
  SharedPreferences.setMockInitialValues({
    rememberedSignInEmailPreferenceKey: 'story-demo@example.com',
    rememberedSignInDisplayNamePreferenceKey: 'Story Demo',
    showInitialSignInPreferenceKey: true,
    passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
  });

  await _pumpSignInScreen(
    tester,
    authNotifier: _RecordingAuthNotifier(),
    passkeysAvailable: true,
    passkeyService: _RecordingPasskeyService(),
  );

  expect(find.byType(TextField), findsNWidgets(2));
  expect(find.text('Not you?'), findsNothing);
  expect(find.byKey(const ValueKey('saved-passkey-primary')), findsNothing);
});
```

- [ ] **Step 2: Run the sign-in widget tests to verify they fail**

Run from `app`:

```powershell
flutter test test/screens/onboarding/sign_in_screen_test.dart
```

Expected: FAIL because the old passkey-first UI still renders.

- [ ] **Step 3: Replace local state selection in `SignInScreen`**

In `app/lib/screens/onboarding/sign_in_screen.dart`, import the provider:

```dart
import '../../providers/sign_in_preference_provider.dart';
```

Replace `_showEmailSignIn` with password-mode state:

```dart
bool _showPasswordSignIn = false;
```

Update `_submit` so returning password mode can use a remembered email:

```dart
Future<void> _submit({String? emailOverride}) async {
  final email = (emailOverride ?? _emailController.text).trim();
  final emailError = emailOverride == null ? _validateEmail(email) : null;
  final passwordError = _validatePassword(_passwordController.text);
  if (emailError != null || passwordError != null) {
    setState(() {
      _emailFieldError = emailError;
      _passwordFieldError = passwordError;
      _errorMessage = null;
    });
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = null;
    _emailFieldError = null;
    _passwordFieldError = null;
  });

  try {
    await ref.read(authProvider.notifier).login(
          email,
          _passwordController.text,
        );
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = friendlySignInErrorMessage(
        e,
        isPasswordSignIn: true,
      );
    });
    return;
  }

  _clearLoadingUnlessAuthenticated();
}
```

At the top of `build`, compute the three states:

```dart
final rememberedSignIn = ref.watch(rememberedSignInPreferenceProvider);
final rememberedEmail = rememberedSignIn.email;
final hasReturningIdentity = rememberedSignIn.hasRememberedIdentity &&
    !rememberedSignIn.showInitialSignIn &&
    rememberedEmail != null;
final rememberedHasLocalPasskey = rememberedEmail != null &&
    passkeyPreference.hasRegisteredEmail(rememberedEmail);
final canUseRememberedPasskey =
    passkeysAvailable && rememberedHasLocalPasskey;
final showPasskeyPriority =
    hasReturningIdentity && canUseRememberedPasskey && !_showPasswordSignIn;
final showReturningPassword =
    hasReturningIdentity && !showPasskeyPriority;
```

- [ ] **Step 4: Extract reusable social sign-in actions**

Move the existing inline Apple and Google button bodies into state methods so the initial and returning states can share the same social section:

```dart
Future<void> _signInWithApple() async {
  _dismissKeyboard();
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  try {
    await ref.read(authProvider.notifier).signInWithApple();
  } on CognitoManagedLoginCancelledException {
    // User intentionally closed the hosted auth sheet.
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _errorMessage = friendlySignInErrorMessage(e);
    });
  } finally {
    _clearLoadingUnlessAuthenticated();
  }
}

Future<void> _signInWithGoogle() async {
  _dismissKeyboard();
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  try {
    await ref.read(authProvider.notifier).signInWithGoogle();
  } on CognitoManagedLoginCancelledException {
    // User intentionally closed the hosted auth sheet.
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _errorMessage = friendlySignInErrorMessage(e);
    });
  } finally {
    _clearLoadingUnlessAuthenticated();
  }
}
```

Add this divider widget below the sign-in state class:

```dart
class _SocialSignInDivider extends StatelessWidget {
  const _SocialSignInDivider();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _SocialSignInButtons extends StatelessWidget {
  const _SocialSignInButtons({
    required this.isLoading,
    required this.onApple,
    required this.onGoogle,
  });

  final bool isLoading;
  final VoidCallback onApple;
  final VoidCallback onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            icon: AppIcons.icon(
              AppIconKey.appleBrand,
              color: Colors.white,
              size: 24,
            ),
            label: const Text('Sign in with Apple'),
            onPressed: isLoading ? null : onApple,
          ),
        ),
        const SizedBox(height: 12),
        _GoogleSignInButton(
          isLoading: isLoading,
          onPressed: onGoogle,
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: Add the personal returning-user widgets**

Replace `_PasskeyFirstSignIn` with these focused widgets in the same file. Start by extracting the current initial form into a widget so the top-level branch stays readable:

```dart
class _InitialEmailPasswordSignIn extends StatelessWidget {
  const _InitialEmailPasswordSignIn({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.emailError,
    required this.passwordError,
    required this.passkeysAvailable,
    required this.isLoading,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onPasswordVisibilityChanged,
    required this.onTypedPasskey,
    required this.onForgotPassword,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? emailError;
  final String? passwordError;
  final bool passkeysAvailable;
  final bool isLoading;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onPasswordVisibilityChanged;
  final VoidCallback onTypedPasskey;
  final VoidCallback onForgotPassword;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Form(
          key: formKey,
          child: Column(
            children: [
              FloatingLabelTextField(
                controller: emailController,
                label: 'Email',
                prefix: AppIcons.icon(
                  AppIconKey.email,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: onEmailChanged,
                errorText: emailError,
                autofillHints: const [AutofillHints.email],
                trailing: passkeysAvailable
                    ? IconButton(
                        key: const ValueKey('email-passkey-sign-in-button'),
                        tooltip: 'Sign in with passkey',
                        visualDensity: VisualDensity.compact,
                        onPressed: isLoading ? null : onTypedPasskey,
                        icon: AppIcons.icon(
                          AppIconKey.passkey,
                          color: colors.primary,
                          size: 20,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 16),
              FloatingLabelTextField(
                controller: passwordController,
                label: 'Password',
                prefix: AppIcons.icon(
                  AppIconKey.password,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                onChanged: onPasswordChanged,
                onSubmitted: (_) {
                  if (!isLoading) onSubmit();
                },
                errorText: passwordError,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.password],
                trailing: IconButton(
                  icon: AppIcons.icon(
                    obscurePassword
                        ? AppIconKey.visibility
                        : AppIconKey.visibilityOff,
                    color: obscurePassword
                        ? colors.onSurfaceVariant
                        : colors.primary,
                  ),
                  onPressed: onPasswordVisibilityChanged,
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: const Text('Sign In'),
          ),
        ),
      ],
    );
  }
}
```

Then add the returning-user widgets:

```dart
class _RememberedIdentityHeader extends StatelessWidget {
  const _RememberedIdentityHeader({
    required this.displayName,
    required this.onNotYou,
  });

  final String displayName;
  final VoidCallback onNotYou;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: textTheme.titleMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                displayName,
                style: textTheme.headlineSmall?.copyWith(
                  color: colors.onSurface,
                  height: 1.12,
                ),
              ),
            ),
            TextButton(
              onPressed: onNotYou,
              child: const Text('Not you?'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasskeyPrioritySignIn extends StatelessWidget {
  const _PasskeyPrioritySignIn({
    required this.email,
    required this.isLoading,
    required this.onPasskeySignIn,
    required this.onPasswordSignIn,
  });

  final String email;
  final bool isLoading;
  final VoidCallback onPasskeySignIn;
  final VoidCallback onPasswordSignIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('saved-passkey-primary'),
            borderRadius: BorderRadius.circular(28),
            onTap: isLoading ? null : onPasskeySignIn,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: AppIcons.icon(
                        AppIconKey.passkey,
                        color: colors.primary,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isLoading ? null : onPasswordSignIn,
          child: const Text('Sign in with password'),
        ),
      ],
    );
  }
}

class _ReturningPasswordSignIn extends StatelessWidget {
  const _ReturningPasswordSignIn({
    required this.passwordController,
    required this.obscurePassword,
    required this.passwordError,
    required this.isLoading,
    required this.canUsePasskey,
    required this.onPasswordVisibilityChanged,
    required this.onPasswordChanged,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onPasskeySignIn,
  });

  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? passwordError;
  final bool isLoading;
  final bool canUsePasskey;
  final VoidCallback onPasswordVisibilityChanged;
  final ValueChanged<String> onPasswordChanged;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onPasskeySignIn;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        FloatingLabelTextField(
          controller: passwordController,
          label: 'Password',
          prefix: AppIcons.icon(
            AppIconKey.password,
            color: colors.onSurfaceVariant,
            size: 20,
          ),
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          onChanged: onPasswordChanged,
          onSubmitted: (_) {
            if (!isLoading) onSubmit();
          },
          errorText: passwordError,
          enableSuggestions: false,
          autocorrect: false,
          autofillHints: const [AutofillHints.password],
          trailing: IconButton(
            icon: AppIcons.icon(
              obscurePassword
                  ? AppIconKey.visibility
                  : AppIconKey.visibilityOff,
              color: obscurePassword ? colors.onSurfaceVariant : colors.primary,
            ),
            onPressed: onPasswordVisibilityChanged,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: isLoading ? null : onForgotPassword,
            child: const Text('Forgot password?'),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: isLoading ? null : onSubmit,
            child: const Text('Sign In'),
          ),
        ),
        if (canUsePasskey) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: isLoading ? null : onPasskeySignIn,
              icon: AppIcons.icon(
                AppIconKey.passkey,
                color: colors.primary,
                size: 18,
              ),
              label: const Text('Sign in with passkey'),
            ),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 6: Wire the new states into the screen**

Inside the main `Column` where the old `_PasskeyFirstSignIn` conditional lived, use this structure:

```dart
if (showPasskeyPriority || showReturningPassword) ...[
  _RememberedIdentityHeader(
    displayName: rememberedSignIn.displayNameOrEmail,
    onNotYou: () {
      ref
          .read(rememberedSignInPreferenceProvider.notifier)
          .showInitialSignIn();
      setState(() {
        _showPasswordSignIn = false;
        _errorMessage = null;
        _emailFieldError = null;
        _passwordFieldError = null;
      });
    },
  ),
  if (showPasskeyPriority)
    _PasskeyPrioritySignIn(
      email: rememberedEmail!,
      isLoading: _isLoading,
      onPasskeySignIn: () => _signInWithPasskey(rememberedEmail),
      onPasswordSignIn: () {
        setState(() {
          _showPasswordSignIn = true;
          _errorMessage = null;
        });
      },
    )
  else
    _ReturningPasswordSignIn(
      passwordController: _passwordController,
      obscurePassword: _obscurePassword,
      passwordError: _passwordFieldError,
      isLoading: _isLoading,
      canUsePasskey: canUseRememberedPasskey,
      onPasswordVisibilityChanged: () => setState(
        () => _obscurePassword = !_obscurePassword,
      ),
      onPasswordChanged: (_) => _clearInlineErrors(),
      onSubmit: () => _submit(emailOverride: rememberedEmail),
      onForgotPassword: () => context.go(AppRoutes.passwordReset),
      onPasskeySignIn: () => _signInWithPasskey(rememberedEmail!),
    ),
  const SizedBox(height: 24),
  _SocialSignInDivider(),
  const SizedBox(height: 24),
  _SocialSignInButtons(
    isLoading: _isLoading,
    onApple: _signInWithApple,
    onGoogle: _signInWithGoogle,
  ),
] else ...[
  _InitialEmailPasswordSignIn(
    formKey: _formKey,
    emailController: _emailController,
    passwordController: _passwordController,
    obscurePassword: _obscurePassword,
    emailError: _emailFieldError,
    passwordError: _passwordFieldError,
    passkeysAvailable: passkeysAvailable,
    isLoading: _isLoading,
    onEmailChanged: (_) => _clearInlineErrors(),
    onPasswordChanged: (_) => _clearInlineErrors(),
    onPasswordVisibilityChanged: () => setState(
      () => _obscurePassword = !_obscurePassword,
    ),
    onTypedPasskey: _signInWithTypedPasskey,
    onForgotPassword: () => context.go(AppRoutes.passwordReset),
    onSubmit: () => _submit(),
  ),
  const SizedBox(height: 24),
  _SocialSignInDivider(),
  const SizedBox(height: 24),
  _SocialSignInButtons(
    isLoading: _isLoading,
    onApple: _signInWithApple,
    onGoogle: _signInWithGoogle,
  ),
  const SizedBox(height: 16),
  Center(
    child: TextButton(
      onPressed: _isLoading
          ? null
          : () => context.go('/onboarding/sign-up'),
      child: const Text("Don't have an account? Sign Up"),
    ),
  ),
]
```

- [ ] **Step 7: Keep initial typed-email passkey behavior**

In the initial email field branch, keep the existing trailing passkey icon:

```dart
trailing: passkeysAvailable
    ? IconButton(
        key: const ValueKey('email-passkey-sign-in-button'),
        tooltip: 'Sign in with passkey',
        visualDensity: VisualDensity.compact,
        onPressed: _isLoading ? null : _signInWithTypedPasskey,
        icon: AppIcons.icon(
          AppIconKey.passkey,
          color: colors.primary,
          size: 20,
        ),
      )
    : null,
```

This preserves the current external-passkey path without making it the main returning-user design.

- [ ] **Step 8: Run the sign-in widget tests to verify they pass**

Run from `app`:

```powershell
flutter test test/screens/onboarding/sign_in_screen_test.dart
```

Expected: PASS.

- [ ] **Step 9: Commit the UI change**

Run from repo root:

```powershell
git status -sb
git add -- app/lib/screens/onboarding/sign_in_screen.dart app/test/screens/onboarding/sign_in_screen_test.dart
git commit -m "feat(app): personalize passkey sign-in"
```

## Task 4: Focused Regression Verification

**Files:**
- Modify only files needed to address failures from the commands below.

- [ ] **Step 1: Run provider and sign-in tests together**

Run from `app`:

```powershell
flutter test test/providers/sign_in_preference_provider_test.dart test/providers/auth_provider_test.dart test/providers/passkey_provider_test.dart test/screens/onboarding/sign_in_screen_test.dart test/services/passkey_service_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run analyzer**

Run from `app`:

```powershell
flutter analyze
```

Expected: exits 0 with no new analyzer issues.

- [ ] **Step 3: Inspect the final diff**

Run from repo root:

```powershell
git status -sb
git diff --stat origin/main...HEAD
git diff --check
```

Expected:

- only app/docs files related to this PR are changed
- `git diff --check` reports no whitespace errors

- [ ] **Step 4: Commit verification-only fixes if any were needed**

Only run this if Step 1 or Step 2 required code/test edits:

```powershell
git status -sb
git add -- app/lib app/test
git commit -m "fix(app): stabilize personal sign-in tests"
```

## Self-Review

- Spec coverage: Task 1 covers local state and the `Not you?` flag. Task 2 covers successful sign-in persistence and display-name fallback. Task 3 covers the initial, returning passkey-priority, returning password, `Not you?`, and typed-email passkey states. Task 4 covers targeted verification.
- Red-flag scan: the plan contains no open work markers or unnamed implementation hooks.
- Type consistency: `RememberedSignInPreference`, `rememberedSignInPreferenceProvider`, `rememberedSignInEmailPreferenceKey`, `rememberedSignInDisplayNamePreferenceKey`, and `showInitialSignInPreferenceKey` are introduced in Task 1 and reused with the same names in later tasks.
