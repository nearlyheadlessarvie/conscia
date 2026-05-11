import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../providers/auth_provider.dart';

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(
    dio: ref.watch(dioProvider),
    messaging: FirebaseMessaging.instance,
  );
  ref.onDispose(service.dispose);
  return service;
});

class PushNotificationService {
  PushNotificationService({
    required Dio dio,
    required FirebaseMessaging messaging,
  })  : _dio = dio,
        _messaging = messaging;

  final Dio _dio;
  final FirebaseMessaging _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _started = false;

  Future<void> start() async {
    if (_started || !ApiConstants.pushNotificationsEnabled) return;
    _started = true;

    final initialized = await _tryInitializeFirebase();
    if (!initialized) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _messaging.getToken();
      await _registerToken(token);

      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
        (token) => unawaited(_registerToken(token)),
      );
    } catch (error) {
      debugPrint('Push notification token registration failed: $error');
    }
  }

  void dispose() {
    unawaited(_tokenRefreshSubscription?.cancel());
    _tokenRefreshSubscription = null;
    _started = false;
  }

  Future<bool> _tryInitializeFirebase() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      return true;
    } on FirebaseException catch (error) {
      debugPrint('Push notifications disabled: ${error.message}');
      return false;
    } catch (error) {
      debugPrint('Push notifications disabled: $error');
      return false;
    }
  }

  Future<void> _registerToken(String? token) async {
    if (token == null || token.trim().isEmpty) return;

    await _dio.post(
      ApiConstants.pushDeviceTokens,
      data: {
        'token': token,
        'platform': _platformLabel(),
      },
    );
  }

  String _platformLabel() {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }
}

class PushNotificationBootstrapper extends ConsumerStatefulWidget {
  const PushNotificationBootstrapper({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  ConsumerState<PushNotificationBootstrapper> createState() =>
      _PushNotificationBootstrapperState();
}

class _PushNotificationBootstrapperState
    extends ConsumerState<PushNotificationBootstrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startIfAuthenticated(ref.read(authProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(
        authProvider, (_, next) => _startIfAuthenticated(next));
    return widget.child;
  }

  void _startIfAuthenticated(AuthState state) {
    if (!state.isAuthenticated) return;
    unawaited(ref.read(pushNotificationServiceProvider).start());
  }
}
