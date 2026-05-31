import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/app_error.dart';
import '../core/network/request_options.dart';
import 'auth_service.dart';

class PasskeyCredential {
  const PasskeyCredential({
    required this.credentialId,
    this.friendlyName,
    this.createdAt,
    this.relyingPartyId,
    this.authenticatorAttachment,
    this.transports = const [],
  });

  factory PasskeyCredential.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'] as String?;
    final transports = json['transports'];

    return PasskeyCredential(
      credentialId: json['credentialId'] as String,
      friendlyName: json['friendlyName'] as String?,
      createdAt: createdAt == null ? null : DateTime.tryParse(createdAt),
      relyingPartyId: json['relyingPartyId'] as String?,
      authenticatorAttachment: json['authenticatorAttachment'] as String?,
      transports: transports is List
          ? transports.whereType<String>().toList(growable: false)
          : const [],
    );
  }

  final String credentialId;
  final String? friendlyName;
  final DateTime? createdAt;
  final String? relyingPartyId;
  final String? authenticatorAttachment;
  final List<String> transports;
}

class PasskeyService {
  PasskeyService({
    required Dio publicDio,
    required Dio authenticatedDio,
    PasskeyAuthenticator? authenticator,
  })  : _publicDio = publicDio,
        _authenticatedDio = authenticatedDio,
        _authenticator =
            authenticator ?? PasskeyAuthenticator(debugMode: kDebugMode);

  final Dio _publicDio;
  final Dio _authenticatedDio;
  final PasskeyAuthenticator _authenticator;

  Future<bool> isSupported() async {
    try {
      if (kIsWeb) {
        final availability = await _authenticator.getAvailability().web();
        return availability.hasPasskeySupport;
      }

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final availability = await _authenticator.getAvailability().android();
          return availability.hasPasskeySupport;
        case TargetPlatform.iOS:
          final availability = await _authenticator.getAvailability().iOS();
          return availability.hasPasskeySupport;
        case TargetPlatform.windows:
          final availability = await _authenticator.getAvailability().windows();
          return availability.hasPasskeySupport;
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.fuchsia:
          return false;
      }
    } catch (_) {
      return false;
    }
  }

  Future<AuthTokens> signIn(String email) async {
    final startResponse = await _publicDio.post(
      ApiConstants.passkeyLoginStart,
      data: {'email': email},
    );
    final startData = startResponse.data as Map<String, dynamic>;
    final request = AuthenticateRequestType.fromJsonString(
      startData['credentialRequestOptions'] as String,
      mediation: MediationType.Required,
      preferImmediatelyAvailableCredentials: true,
    );
    final platformResponse = await _authenticator.authenticate(request);

    final completeResponse = await _publicDio.post(
      ApiConstants.passkeyLoginComplete,
      data: {
        'email': email,
        'session': startData['session'],
        'challengeName': startData['challengeName'],
        'credential': platformResponse.toJsonString(),
      },
    );

    return AuthTokens.fromJson(completeResponse.data as Map<String, dynamic>);
  }

  Future<void> registerCurrentUserPasskey() async {
    final startResponse = await _authenticatedDio.post(
      ApiConstants.passkeyRegisterStart,
      options: Options(
        extra: {
          useAccessTokenRequestExtraKey: true,
        },
      ),
    );
    final startData = startResponse.data as Map<String, dynamic>;
    final request = RegisterRequestType.fromJsonString(
      startData['credentialCreationOptions'] as String,
    );
    final platformResponse = await _authenticator.register(request);

    await _authenticatedDio.post(
      ApiConstants.passkeyRegisterComplete,
      data: {
        'credential': platformResponse.toJsonString(),
      },
      options: Options(
        extra: {
          useAccessTokenRequestExtraKey: true,
        },
      ),
    );
  }

  Future<List<PasskeyCredential>> listCurrentUserPasskeys() async {
    final response = await _authenticatedDio.get(
      ApiConstants.passkeys,
      options: Options(
        extra: {
          useAccessTokenRequestExtraKey: true,
        },
      ),
    );

    final data = response.data;
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => PasskeyCredential.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  Future<void> deleteCurrentUserPasskey(String credentialId) async {
    await _authenticatedDio.delete(
      ApiConstants.passkeyCredential(credentialId),
      options: Options(
        extra: {
          useAccessTokenRequestExtraKey: true,
        },
      ),
    );
  }
}

bool isPasskeyCancellation(Object error) =>
    error is PasskeyAuthCancelledException;

String passkeyDeviceRemovalInstructions({
  TargetPlatform? platform,
  bool isWeb = kIsWeb,
}) {
  if (isWeb) {
    return 'Also remove the saved passkey from your browser or password manager for getconscia.com before setting it up again.';
  }

  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.android =>
      'Also remove the saved passkey in Google Password Manager > Passwords & passkeys > getconscia.com before setting it up again.',
    TargetPlatform.iOS =>
      'Also remove the saved passkey in iOS Settings > Passwords > getconscia.com before setting it up again.',
    TargetPlatform.macOS =>
      'Also remove the saved passkey in macOS System Settings > Passwords > getconscia.com before setting it up again.',
    TargetPlatform.windows =>
      'Also remove the saved passkey from Windows passkey settings or your browser password manager before setting it up again.',
    TargetPlatform.linux ||
    TargetPlatform.fuchsia =>
      'Also remove the saved passkey from this device or password manager before setting it up again.',
  };
}

bool isPasskeyCredentialUnavailable(Object error) {
  if (error is NoCredentialsAvailableException) {
    return true;
  }

  if (error is UnhandledAuthenticatorException) {
    final details = [
      error.code,
      error.message,
      error.details?.toString(),
    ].whereType<String>().join(' ').toLowerCase();

    return details.contains('no credential') ||
        details.contains('no credentials') ||
        details.contains('credential') ||
        details.contains('android-unhandled');
  }

  return false;
}

String friendlyPasskeyErrorMessage(Object error) {
  if (error is AppError || error is DioException) {
    return AppError.from(error, log: false).userMessage;
  }

  if (error is PlatformException) {
    return switch (error.code) {
      'domain-not-associated' =>
        'Passkeys are not fully configured for this app yet.',
      'deviceNotSupported' => 'This device does not support passkeys yet.',
      'ios-security-key-timeout' =>
        'Passkey verification timed out. Please try again.',
      _ => 'Passkey sign-in is unavailable right now.',
    };
  }

  return switch (error) {
    NoCredentialsAvailableException() =>
      'No passkey was found for this account on this device.',
    DomainNotAssociatedException() =>
      'Passkeys are not fully configured for this app yet.',
    DeviceNotSupportedException() ||
    PasskeyUnsupportedException() =>
      'This device does not support passkeys yet.',
    MissingGoogleSignInException() =>
      'Sign in to a Google account on this device to use passkeys.',
    SyncAccountNotAvailableException() =>
      'This device is not ready for passkeys yet. Try again after restarting it.',
    ExcludeCredentialsCanNotBeRegisteredException() =>
      'A passkey may already be saved on this device. ${passkeyDeviceRemovalInstructions()}',
    NoCreateOptionException() =>
      'A passkey may already be saved on this device. ${passkeyDeviceRemovalInstructions()}',
    TimeoutException() => 'Passkey verification timed out. Please try again.',
    PasskeyAuthCancelledException() => 'Passkey sign-in was cancelled.',
    UnhandledAuthenticatorException() =>
      'Passkey sign-in could not use the saved credential on this device. Sign in with email, then remove and set up the passkey again.',
    _ => 'Passkey sign-in is unavailable right now.',
  };
}
