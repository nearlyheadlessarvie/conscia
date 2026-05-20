import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../services/passkey_service.dart';
import 'auth_provider.dart';

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
