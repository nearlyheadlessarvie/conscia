import 'dart:convert';

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

enum PasskeyOperation { signIn, register, delete }

class ExistingPasskeyRegistrationException implements Exception {
  const ExistingPasskeyRegistrationException(this.source);

  final Object source;
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

  Future<String?> registerCurrentUserPasskey() async {
    RegisterRequestType? request;
    try {
      final startResponse = await _authenticatedDio.post(
        ApiConstants.passkeyRegisterStart,
        options: Options(
          extra: {
            useAccessTokenRequestExtraKey: true,
          },
        ),
      );
      final startData = startResponse.data as Map<String, dynamic>;
      request = _registerRequestFromJsonString(
        startData['credentialCreationOptions'] as String,
      );
      final platformResponse = await _authenticator.register(request);
      final credentialId = platformResponse.id.trim().isNotEmpty
          ? platformResponse.id.trim()
          : platformResponse.rawId.trim();

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
      return credentialId.isEmpty ? null : credentialId;
    } catch (error, stackTrace) {
      await _recordPasskeyRegistrationFailure(error, request);
      if (request != null &&
          request.excludeCredentials.isNotEmpty &&
          _isExistingCredentialRegistrationFailure(error)) {
        Error.throwWithStackTrace(
          ExistingPasskeyRegistrationException(error),
          stackTrace,
        );
      }

      Error.throwWithStackTrace(error, stackTrace);
    }
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

  Future<void> _recordPasskeyRegistrationFailure(
    Object error,
    RegisterRequestType? request,
  ) async {
    try {
      await _authenticatedDio.post(
        ApiConstants.clientDiagnostics,
        data: {
          'eventName': 'passkey.register.failed',
          'level': 'warning',
          'operation': 'register',
          'platform': _platformLabel(),
          'errorType': error.runtimeType.toString(),
          if (_errorCode(error) case final code?) 'errorCode': code,
          if (_errorMessage(error) case final message?) 'errorMessage': message,
          'context': _registrationContext(request),
        },
        options: Options(
          extra: {
            useAccessTokenRequestExtraKey: true,
          },
        ),
      );
    } catch (_) {
      // Diagnostics must never mask the original passkey setup failure.
    }
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

bool _isExistingCredentialRegistrationFailure(Object error) =>
    error is PlatformException ||
    error is ExcludeCredentialsCanNotBeRegisteredException ||
    error is NoCreateOptionException;

String _platformLabel() {
  if (kIsWeb) {
    return 'web';
  }

  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}

String? _errorCode(Object error) => switch (error) {
      PlatformException() => error.code,
      UnhandledAuthenticatorException() => error.code,
      DioException() => error.response?.statusCode?.toString(),
      _ => null,
    };

String? _errorMessage(Object error) => switch (error) {
      PlatformException() => error.message,
      UnhandledAuthenticatorException() => error.message,
      DioException() => error.message,
      _ => null,
    };

Map<String, String> _registrationContext(RegisterRequestType? request) {
  if (request == null) {
    return const {};
  }

  return {
    'rpId': request.relyingParty.id,
    'excludeCredentialsCount': request.excludeCredentials.length.toString(),
    if (request.authSelectionType case final selection?) ...{
      'residentKey': selection.residentKey,
      'userVerification': selection.userVerification,
    },
  };
}

RegisterRequestType _registerRequestFromJsonString(String jsonString) {
  final decoded = jsonDecode(jsonString);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('Expected JSON object, got ${decoded.runtimeType}');
  }

  final excludeCredentials = decoded['excludeCredentials'];
  if (excludeCredentials is List) {
    decoded['excludeCredentials'] = excludeCredentials.map((credential) {
      if (credential is! Map) {
        return credential;
      }

      final normalized = Map<String, dynamic>.from(credential);
      normalized.putIfAbsent('transports', () => <String>[]);
      return normalized;
    }).toList(growable: false);
  }

  return RegisterRequestType.fromJson(decoded);
}

String friendlyPasskeyErrorMessage(
  Object error, {
  PasskeyOperation operation = PasskeyOperation.signIn,
}) {
  if (error is AppError || error is DioException) {
    final originalError = error is AppError ? error.originalError : error;
    final genericPasskeyMessage =
        _genericPasskeyApiFailureMessage(originalError, operation);
    if (genericPasskeyMessage != null) {
      return genericPasskeyMessage;
    }
    return AppError.from(error, log: false).userMessage;
  }

  if (error is ExistingPasskeyRegistrationException) {
    return 'A passkey is already registered for this account. Remove it from Security settings and from this device before setting it up again.';
  }

  if (error is PlatformException) {
    return switch (error.code) {
      'domain-not-associated' =>
        'Passkeys are not fully configured for this app yet.',
      'deviceNotSupported' => 'This device does not support passkeys yet.',
      'ios-security-key-timeout' =>
        'Passkey verification timed out. Please try again.',
      _ =>
        'Passkey ${_passkeyOperationLabel(operation)} is unavailable right now. Code: ${error.code}',
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

String _passkeyOperationLabel(PasskeyOperation operation) {
  return switch (operation) {
    PasskeyOperation.register => 'setup',
    PasskeyOperation.delete => 'removal',
    PasskeyOperation.signIn => 'sign-in',
  };
}

String? _genericPasskeyApiFailureMessage(
  Object error,
  PasskeyOperation operation,
) {
  final hasNoServerMessage = switch (error) {
    DioException() => _dioHasNoServerMessage(error),
    _ => false,
  };
  if (!hasNoServerMessage) return null;

  return switch (operation) {
    PasskeyOperation.register => 'Passkey setup failed. Please try again.',
    PasskeyOperation.delete =>
      'Passkey removal failed. Please refresh and try again.',
    PasskeyOperation.signIn => 'Passkey sign-in failed. Please try again.',
  };
}

bool _dioHasNoServerMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map) {
    return error.response != null;
  }

  return !_hasText(data['message']) && !_hasText(data['error']);
}

bool _hasText(Object? value) => value is String && value.trim().isNotEmpty;
