import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../services/passkey_service.dart';
import 'auth_provider.dart';
import 'usage_provider.dart';

const passkeyRegisteredEmailsPreferenceKey = 'passkey_registered_emails';
const passkeyRegisteredCredentialIdsPreferenceKey =
    'passkey_registered_credential_ids';
const passkeyFirstSignInEnabledPreferenceKey = 'passkey_first_sign_in_enabled';

class PasskeySignInPreference {
  const PasskeySignInPreference({
    required this.registeredEmails,
    required this.credentialIdsByEmail,
    required this.isPasskeyFirstEnabled,
  });

  final List<String> registeredEmails;
  final Map<String, String> credentialIdsByEmail;
  final bool isPasskeyFirstEnabled;

  bool get canUsePasskeyFirst => registeredEmails.isNotEmpty;

  bool hasRegisteredEmail(String email) {
    return registeredEmails.contains(_normalizePasskeyEmail(email));
  }

  String? credentialIdForEmail(String email) {
    return credentialIdsByEmail[_normalizePasskeyEmail(email)];
  }

  PasskeySignInPreference copyWith({
    List<String>? registeredEmails,
    Map<String, String>? credentialIdsByEmail,
    bool? isPasskeyFirstEnabled,
  }) {
    return PasskeySignInPreference(
      registeredEmails: registeredEmails ?? this.registeredEmails,
      credentialIdsByEmail: credentialIdsByEmail ?? this.credentialIdsByEmail,
      isPasskeyFirstEnabled:
          isPasskeyFirstEnabled ?? this.isPasskeyFirstEnabled,
    );
  }
}

class PasskeySignInPreferenceNotifier
    extends StateNotifier<PasskeySignInPreference> {
  PasskeySignInPreferenceNotifier(this._prefs)
      : super(
          PasskeySignInPreference(
            registeredEmails: _loadRegisteredEmails(_prefs),
            credentialIdsByEmail: _loadRegisteredCredentialIds(_prefs),
            isPasskeyFirstEnabled:
                _prefs.getBool(passkeyFirstSignInEnabledPreferenceKey) ?? false,
          ),
        );

  final SharedPreferences _prefs;

  Future<void> registerCredential(String email, String? credentialId) async {
    final normalized = _normalizePasskeyEmail(email);
    final normalizedCredentialId = credentialId?.trim() ?? '';
    if (normalized.isEmpty) return;

    final emails = [...state.registeredEmails];
    if (!emails.contains(normalized)) {
      emails.add(normalized);
    }

    final credentialIds = Map<String, String>.from(state.credentialIdsByEmail);
    if (normalizedCredentialId.isNotEmpty) {
      credentialIds[normalized] = normalizedCredentialId;
    }

    state = state.copyWith(
      registeredEmails: List.unmodifiable(emails),
      credentialIdsByEmail: Map.unmodifiable(credentialIds),
      isPasskeyFirstEnabled: true,
    );
    await _prefs.setStringList(passkeyRegisteredEmailsPreferenceKey, emails);
    await _prefs.setString(
      passkeyRegisteredCredentialIdsPreferenceKey,
      jsonEncode(credentialIds),
    );
    await _prefs.setBool(passkeyFirstSignInEnabledPreferenceKey, true);
  }

  Future<void> forgetEmail(String email) async {
    final normalized = _normalizePasskeyEmail(email);
    if (normalized.isEmpty) return;

    final emails = state.registeredEmails
        .where((registeredEmail) => registeredEmail != normalized)
        .toList(growable: false);
    final credentialIds = Map<String, String>.from(state.credentialIdsByEmail)
      ..remove(normalized);
    final passkeyFirstEnabled = emails.isNotEmpty;

    state = state.copyWith(
      registeredEmails: List.unmodifiable(emails),
      credentialIdsByEmail: Map.unmodifiable(credentialIds),
      isPasskeyFirstEnabled: passkeyFirstEnabled,
    );
    await _prefs.setStringList(passkeyRegisteredEmailsPreferenceKey, emails);
    await _prefs.setString(
      passkeyRegisteredCredentialIdsPreferenceKey,
      jsonEncode(credentialIds),
    );
    await _prefs.setBool(
      passkeyFirstSignInEnabledPreferenceKey,
      passkeyFirstEnabled,
    );
  }

  Future<void> setPasskeyFirstEnabled(bool value) async {
    final enabled = value && state.registeredEmails.isNotEmpty;
    state = state.copyWith(isPasskeyFirstEnabled: enabled);
    await _prefs.setBool(passkeyFirstSignInEnabledPreferenceKey, enabled);
  }
}

final passkeySignInPreferenceProvider = StateNotifierProvider<
    PasskeySignInPreferenceNotifier, PasskeySignInPreference>((ref) {
  return PasskeySignInPreferenceNotifier(ref.watch(sharedPreferencesProvider));
});

List<String> _loadRegisteredEmails(SharedPreferences prefs) {
  final normalizedEmails = <String>[];
  final credentialIds = _loadRegisteredCredentialIds(prefs);
  for (final email
      in prefs.getStringList(passkeyRegisteredEmailsPreferenceKey) ??
          const <String>[]) {
    final normalized = _normalizePasskeyEmail(email);
    if (normalized.isNotEmpty && !normalizedEmails.contains(normalized)) {
      normalizedEmails.add(normalized);
    }
  }
  for (final email in credentialIds.keys) {
    if (!normalizedEmails.contains(email)) {
      normalizedEmails.add(email);
    }
  }
  return List.unmodifiable(normalizedEmails);
}

Map<String, String> _loadRegisteredCredentialIds(SharedPreferences prefs) {
  final raw = prefs.getString(passkeyRegisteredCredentialIdsPreferenceKey);
  if (raw == null || raw.trim().isEmpty) {
    return const {};
  }

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const {};
    }

    final credentialIds = <String, String>{};
    for (final entry in decoded.entries) {
      final email = _normalizePasskeyEmail(entry.key.toString());
      final credentialId = entry.value?.toString().trim() ?? '';
      if (email.isNotEmpty && credentialId.isNotEmpty) {
        credentialIds[email] = credentialId;
      }
    }
    return Map.unmodifiable(credentialIds);
  } catch (_) {
    return const {};
  }
}

String _normalizePasskeyEmail(String email) => email.trim().toLowerCase();

final passkeyServiceProvider = Provider<PasskeyService>((ref) {
  return PasskeyService(
    publicDio: ref.watch(authDioProvider),
    authenticatedDio: ref.watch(dioProvider),
  );
});

final passkeyAvailabilityProvider = FutureProvider<bool>((ref) async {
  if (ApiConstants.useMockAuth) {
    return false;
  }

  return ref.watch(passkeyServiceProvider).isSupported();
});

final currentSessionSupportsPasskeysProvider = Provider<bool>((ref) {
  if (ApiConstants.useMockAuth) {
    return false;
  }

  final accessToken = ref.watch(authProvider).accessToken;
  if (accessToken == null || accessToken.split('.').length != 3) {
    return false;
  }

  try {
    final payload = accessToken.split('.')[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final claims = jsonDecode(decoded) as Map<String, dynamic>;
    final issuer = claims['iss'] as String?;
    return issuer?.contains('cognito-idp.') ?? false;
  } catch (_) {
    return false;
  }
});
