import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:conscia_app/services/push_notification_service.dart';

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
    this.notificationSettings = _authorizedNotificationSettings,
    this.token,
    Stream<String>? tokenRefreshStream,
  }) : _tokenRefreshStream = tokenRefreshStream ?? const Stream.empty();

  final NotificationSettings notificationSettings;
  final String? token;
  final Stream<String> _tokenRefreshStream;
  int foregroundPresentationCallCount = 0;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshStream;

  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    return notificationSettings;
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
}
