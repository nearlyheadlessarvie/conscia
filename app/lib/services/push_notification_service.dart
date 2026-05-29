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
    pushNotificationsEnabled: ApiConstants.pushNotificationsEnabled,
    initializeFirebase: initializePushNotificationFirebase,
    messagingClientFactory: FirebasePushMessagingClient.new,
  );
  ref.onDispose(service.dispose);
  return service;
});

typedef PushFirebaseInitializer = Future<bool> Function();
typedef PushMessagingClientFactory = PushMessagingClient Function();

abstract interface class PushMessagingClient {
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  });

  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  });

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;
}

class FirebasePushMessagingClient implements PushMessagingClient {
  FirebasePushMessagingClient() : _messaging = FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) {
    return _messaging.requestPermission(
      alert: alert,
      badge: badge,
      sound: sound,
    );
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) {
    return _messaging.setForegroundNotificationPresentationOptions(
      alert: alert,
      badge: badge,
      sound: sound,
    );
  }
}

Future<bool> initializePushNotificationFirebase() async {
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

class PushNotificationService {
  PushNotificationService({
    required Dio dio,
    required bool pushNotificationsEnabled,
    required PushFirebaseInitializer initializeFirebase,
    required PushMessagingClientFactory messagingClientFactory,
  })  : _dio = dio,
        _pushNotificationsEnabled = pushNotificationsEnabled,
        _initializeFirebase = initializeFirebase,
        _messagingClientFactory = messagingClientFactory;

  final Dio _dio;
  final bool _pushNotificationsEnabled;
  final PushFirebaseInitializer _initializeFirebase;
  final PushMessagingClientFactory _messagingClientFactory;
  PushMessagingClient? _messaging;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _started = false;

  Future<void> start() async {
    if (_started || !_pushNotificationsEnabled) return;
    _started = true;

    final initialized = await _initializeFirebase();
    if (!initialized) return;

    try {
      final messaging = _messaging ??= _messagingClientFactory();
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      await _enableForegroundPresentationOnIos(messaging);

      final token = await messaging.getToken();
      await _registerToken(token);

      _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen(
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

  Future<void> _enableForegroundPresentationOnIos(
    PushMessagingClient messaging,
  ) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
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
