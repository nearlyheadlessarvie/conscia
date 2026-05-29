import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../providers/auth_provider.dart';
import '../screens/dashboard/widgets/in_app_alert_banner.dart';

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
  Future<RemoteMessage?> getInitialMessage();

  Stream<RemoteMessage> get onMessage;

  Stream<RemoteMessage> get onMessageOpenedApp;

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
  Future<RemoteMessage?> getInitialMessage() => _messaging.getInitialMessage();

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

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

class PushForegroundNotification {
  const PushForegroundNotification({
    required this.title,
    required this.message,
    this.route,
  });

  final String title;
  final String message;
  final String? route;
}

final pushForegroundNotificationProvider =
    StateProvider<PushForegroundNotification?>((ref) => null);

String? pushNotificationRoute(RemoteMessage message) {
  final route = message.data['route']?.toString().trim();
  if (route == null || route.isEmpty) {
    return null;
  }

  return route;
}

PushForegroundNotification? pushForegroundNotificationFromMessage(
  RemoteMessage message,
) {
  final title = message.notification?.title?.trim() ?? '';
  final body = message.notification?.body?.trim() ?? '';
  if (title.isEmpty && body.isEmpty) {
    return null;
  }

  return PushForegroundNotification(
    title: title.isEmpty ? body : title,
    message: title.isEmpty ? '' : body,
    route: pushNotificationRoute(message),
  );
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
  bool _initialized = false;
  bool _started = false;

  Future<bool> initialize() async {
    if (_initialized || !_pushNotificationsEnabled) {
      return _initialized;
    }

    final initialized = await _initializeFirebase();
    if (!initialized) return false;

    try {
      final messaging = _messaging ??= _messagingClientFactory();
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return false;
      }

      await _enableForegroundPresentationOnIos(messaging);
      _initialized = true;
      return true;
    } catch (error) {
      debugPrint('Push notification initialization failed: $error');
      return false;
    }
  }

  Future<void> start() async {
    if (_started || !_pushNotificationsEnabled) return;

    final initialized = await initialize();
    if (!initialized) return;

    final messaging = _messaging ??= _messagingClientFactory();
    _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen(
      (token) => unawaited(_registerToken(token)),
    );
    _started = true;

    try {
      final token = await messaging.getToken();
      await _registerToken(token);
    } catch (error) {
      debugPrint('Push notification token registration failed: $error');
    }
  }

  Stream<RemoteMessage> get onMessage =>
      _messaging?.onMessage ?? const Stream<RemoteMessage>.empty();

  Stream<RemoteMessage> get onMessageOpenedApp =>
      _messaging?.onMessageOpenedApp ?? const Stream<RemoteMessage>.empty();

  Future<RemoteMessage?> getInitialMessage() async {
    final initialized = await initialize();
    if (!initialized) {
      return null;
    }

    return _messaging?.getInitialMessage();
  }

  void dispose() {
    unawaited(_tokenRefreshSubscription?.cancel());
    _tokenRefreshSubscription = null;
    _initialized = false;
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
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<PushNotificationBootstrapper> createState() =>
      _PushNotificationBootstrapperState();
}

class _PushNotificationBootstrapperState
    extends ConsumerState<PushNotificationBootstrapper> {
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedAppSubscription;
  bool _notificationListenersAttached = false;
  bool _handledInitialMessage = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeNotifications());
    _startIfAuthenticated(ref.read(authProvider));
  }

  @override
  void dispose() {
    unawaited(_messageSubscription?.cancel());
    unawaited(_messageOpenedAppSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(
        authProvider, (_, next) => _startIfAuthenticated(next));
    return widget.child;
  }

  Future<void> _initializeNotifications() async {
    final service = ref.read(pushNotificationServiceProvider);
    final initialized = await service.initialize();
    if (!mounted || !initialized) {
      return;
    }

    _attachNotificationListeners(service);
    await _handleInitialMessage(service);
  }

  void _attachNotificationListeners(PushNotificationService service) {
    if (_notificationListenersAttached) {
      return;
    }

    _notificationListenersAttached = true;
    _messageSubscription =
        service.onMessage.listen(_showForegroundNotification);
    _messageOpenedAppSubscription =
        service.onMessageOpenedApp.listen(_routeNotification);
  }

  Future<void> _handleInitialMessage(PushNotificationService service) async {
    if (_handledInitialMessage) {
      return;
    }

    _handledInitialMessage = true;
    final message = await service.getInitialMessage();
    if (!mounted || message == null) {
      return;
    }

    _routeNotification(message);
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = pushForegroundNotificationFromMessage(message);
    if (notification == null) {
      return;
    }

    ref.read(pushForegroundNotificationProvider.notifier).state = notification;
  }

  void _routeNotification(RemoteMessage message) {
    final route = pushNotificationRoute(message);
    if (route == null) {
      return;
    }

    ref.read(pushForegroundNotificationProvider.notifier).state = null;
    widget.router.go(route);
  }

  void _startIfAuthenticated(AuthState state) {
    if (!state.isAuthenticated) return;
    unawaited(ref.read(pushNotificationServiceProvider).start());
  }
}

class PushNotificationOverlay extends ConsumerWidget {
  const PushNotificationOverlay({
    required this.router,
    super.key,
  });

  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notification = ref.watch(pushForegroundNotificationProvider);
    if (notification == null) {
      return const SizedBox.shrink();
    }

    void dismiss() {
      ref.read(pushForegroundNotificationProvider.notifier).state = null;
    }

    void openRoute() {
      dismiss();
      final route = notification.route;
      if (route == null) {
        return;
      }

      router.go(route);
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: InAppAlertBanner(
              title: notification.title,
              message: notification.message,
              onTap: notification.route == null ? null : openRoute,
              onDismiss: dismiss,
            ),
          ),
        ),
      ),
    );
  }
}
