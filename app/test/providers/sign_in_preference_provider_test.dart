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
