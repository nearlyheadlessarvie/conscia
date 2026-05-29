import 'dart:async';

import 'package:conscia_app/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:conscia_app/services/push_notification_service.dart';
import 'package:conscia_app/services/auth_service.dart';

const _authorizedNotificationSettings = NotificationSettings(
  alert: AppleNotificationSetting.enabled,
  announcement: AppleNotificationSetting.notSupported,
  authorizationStatus: AuthorizationStatus.authorized,
  badge: AppleNotificationSetting.enabled,
  carPlay: AppleNotificationSetting.notSupported,
  lockScreen: AppleNotificationSetting.enabled,
  notificationCenter: AppleNotificationSetting.enabled,
  showPreviews: AppleShowPreviewSetting.always,
  timeSensitive: AppleNotificationSetting.notSupported,
  criticalAlert: AppleNotificationSetting.notSupported,
  sound: AppleNotificationSetting.enabled,
  providesAppNotificationSettings: AppleNotificationSetting.notSupported,
);

class _FakePushMessagingClient implements PushMessagingClient {
  _FakePushMessagingClient({
    this.initialMessage,
    Stream<String>? tokenRefreshStream,
    Stream<RemoteMessage>? messageStream,
    Stream<RemoteMessage>? messageOpenedAppStream,
  })  : _tokenRefreshStream = tokenRefreshStream ?? const Stream.empty(),
        _messageStream = messageStream ?? const Stream.empty(),
        _messageOpenedAppStream =
            messageOpenedAppStream ?? const Stream.empty();

  final RemoteMessage? initialMessage;
  final Stream<String> _tokenRefreshStream;
  final Stream<RemoteMessage> _messageStream;
  final Stream<RemoteMessage> _messageOpenedAppStream;
  int foregroundPresentationCallCount = 0;

  @override
  Future<RemoteMessage?> getInitialMessage() async => initialMessage;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<RemoteMessage> get onMessage => _messageStream;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp => _messageOpenedAppStream;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshStream;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    return _authorizedNotificationSettings;
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    required bool alert,
    required bool badge,
    required bool sound,
  }) async {
    if (alert && badge && sound) {
      foregroundPresentationCallCount += 1;
    }
  }
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async {
    return null;
  }
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(
          _FakeAuthService(),
          _FakeSecureStorage(),
          autoRestoreSession: false,
        ) {
    state = initialState;
  }
}

GoRouter _pushTestRouter({String initialLocation = '/'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Text('home-screen'),
        ),
      ),
      GoRoute(
        path: '/settings/family-space/invites',
        builder: (context, state) => Scaffold(
          body: Text('invite-route:${state.uri.toString()}'),
        ),
      ),
    ],
  );
}

RemoteMessage _remoteMessage({
  String? title,
  String? body,
  String? route,
}) {
  return RemoteMessage.fromMap({
    'data': {
      if (route != null) 'route': route,
    },
    if (title != null || body != null)
      'notification': {
        if (title != null) 'title': title,
        if (body != null) 'body': body,
      },
  });
}

Future<void> _pumpPushApp(
  WidgetTester tester, {
  required PushNotificationService service,
}) async {
  final authNotifier = _TestAuthNotifier(
    const AuthState(
      status: AuthStatus.authenticated,
      userId: 'user-1',
    ),
  );
  final router = _pushTestRouter();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authProvider.overrideWith((ref) => authNotifier),
        pushNotificationServiceProvider.overrideWithValue(service),
      ],
      child: PushNotificationBootstrapper(
        router: router,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                PushNotificationOverlay(router: router),
              ],
            );
          },
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump();
}

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('push service can start with push disabled without touching Firebase',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final service = container.read(pushNotificationServiceProvider);

    await service.start();
  });

  test('push service enables iOS foreground presentation after permission',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final messagingClient = _FakePushMessagingClient();
    final service = PushNotificationService(
      dio: Dio(),
      pushNotificationsEnabled: true,
      initializeFirebase: () async => true,
      messagingClientFactory: () => messagingClient,
    );

    await service.start();

    expect(messagingClient.foregroundPresentationCallCount, 1);
  });

  testWidgets('push bootstrapper routes notification opens using data.route',
      (tester) async {
    final openedMessageController = StreamController<RemoteMessage>.broadcast();
    addTearDown(openedMessageController.close);
    final service = PushNotificationService(
      dio: Dio(),
      pushNotificationsEnabled: true,
      initializeFirebase: () async => true,
      messagingClientFactory: () => _FakePushMessagingClient(
        messageOpenedAppStream: openedMessageController.stream,
      ),
    );

    await _pumpPushApp(tester, service: service);

    openedMessageController.add(
      _remoteMessage(
        route: '/settings/family-space/invites?inviteId=invite-123',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'invite-route:/settings/family-space/invites?inviteId=invite-123',
      ),
      findsOneWidget,
    );
  });

  testWidgets('push bootstrapper routes cold starts using initial message',
      (tester) async {
    final service = PushNotificationService(
      dio: Dio(),
      pushNotificationsEnabled: true,
      initializeFirebase: () async => true,
      messagingClientFactory: () => _FakePushMessagingClient(
        initialMessage: _remoteMessage(
          route: '/settings/family-space/invites?inviteId=invite-123',
        ),
      ),
    );

    await _pumpPushApp(tester, service: service);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'invite-route:/settings/family-space/invites?inviteId=invite-123',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'foreground push banner shows notification content and routes on tap',
      (tester) async {
    final messageController = StreamController<RemoteMessage>.broadcast();
    addTearDown(messageController.close);
    final service = PushNotificationService(
      dio: Dio(),
      pushNotificationsEnabled: true,
      initializeFirebase: () async => true,
      messagingClientFactory: () => _FakePushMessagingClient(
        messageStream: messageController.stream,
      ),
    );

    await _pumpPushApp(tester, service: service);

    messageController.add(
      _remoteMessage(
        title: 'Family invite',
        body: 'You were invited to Santos Household.',
        route: '/settings/family-space/invites?inviteId=invite-123',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Family invite'), findsOneWidget);
    expect(find.text('You were invited to Santos Household.'), findsOneWidget);

    await tester.tap(find.text('Family invite'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'invite-route:/settings/family-space/invites?inviteId=invite-123',
      ),
      findsOneWidget,
    );
  });
}
