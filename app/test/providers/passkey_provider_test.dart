import 'package:conscia_app/providers/passkey_provider.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('passkey preference stores normalized registered emails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(passkeySignInPreferenceProvider.notifier);
    await notifier.registerCredential(
      ' Story-Demo@Example.COM ',
      'credential-id',
    );
    await notifier.registerCredential(
      'story-demo@example.com',
      'credential-id',
    );
    await notifier.setPasskeyFirstEnabled(true);

    final preference = container.read(passkeySignInPreferenceProvider);
    expect(preference.registeredEmails, ['story-demo@example.com']);
    expect(
      preference.credentialIdForEmail('STORY-DEMO@example.com'),
      'credential-id',
    );
    expect(preference.isPasskeyFirstEnabled, isTrue);
    expect(preference.canUsePasskeyFirst, isTrue);
    expect(
      prefs.getStringList(passkeyRegisteredEmailsPreferenceKey),
      ['story-demo@example.com'],
    );
    expect(
      prefs.getString(passkeyRegisteredCredentialIdsPreferenceKey),
      '{"story-demo@example.com":"credential-id"}',
    );
    expect(prefs.getBool(passkeyFirstSignInEnabledPreferenceKey), isTrue);
  });

  test('passkey preference forgets saved emails and disables passkey first',
      () async {
    SharedPreferences.setMockInitialValues({
      passkeyRegisteredEmailsPreferenceKey: [
        'one@example.com',
        'two@example.com',
      ],
      passkeyRegisteredCredentialIdsPreferenceKey:
          '{"one@example.com":"credential-one","two@example.com":"credential-two"}',
      passkeyFirstSignInEnabledPreferenceKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(passkeySignInPreferenceProvider.notifier);
    await notifier.forgetEmail('ONE@example.com');

    expect(
      container.read(passkeySignInPreferenceProvider).registeredEmails,
      ['two@example.com'],
    );
    expect(
      container
          .read(passkeySignInPreferenceProvider)
          .credentialIdForEmail('two@example.com'),
      'credential-two',
    );
    expect(prefs.getBool(passkeyFirstSignInEnabledPreferenceKey), isTrue);

    await notifier.forgetEmail('two@example.com');

    final preference = container.read(passkeySignInPreferenceProvider);
    expect(preference.registeredEmails, isEmpty);
    expect(preference.credentialIdsByEmail, isEmpty);
    expect(preference.isPasskeyFirstEnabled, isFalse);
    expect(prefs.getBool(passkeyFirstSignInEnabledPreferenceKey), isFalse);
  });

  test('passkey first sign-in is automatic for saved local accounts', () async {
    SharedPreferences.setMockInitialValues({
      passkeyRegisteredEmailsPreferenceKey: ['story-demo@example.com'],
      passkeyFirstSignInEnabledPreferenceKey: false,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final preference = container.read(passkeySignInPreferenceProvider);

    expect(preference.registeredEmails, ['story-demo@example.com']);
    expect(preference.isPasskeyFirstEnabled, isFalse);
    expect(preference.canUsePasskeyFirst, isTrue);
  });
}
