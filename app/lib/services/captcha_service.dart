import 'dart:io' show Platform;

import 'package:recaptcha_enterprise_flutter/recaptcha_enterprise_flutter.dart';

import '../core/constants/api_constants.dart';

enum CaptchaAction {
  signup('signup'),
  resendConfirmation('resend_confirmation'),
  passwordResetStart('password_reset_start');

  const CaptchaAction(this.value);

  final String value;
}

class CaptchaChallenge {
  final String token;
  final String siteKey;

  const CaptchaChallenge({
    required this.token,
    required this.siteKey,
  });
}

abstract class CaptchaService {
  Future<CaptchaChallenge?> execute(CaptchaAction action);
}

class GoogleCaptchaService implements CaptchaService {
  RecaptchaClient? _client;

  @override
  Future<CaptchaChallenge?> execute(CaptchaAction action) async {
    final siteKey = _siteKey;
    if (siteKey.isEmpty) {
      return null;
    }

    final client = _client ??= await Recaptcha.fetchClient(siteKey);
    final token = await client.execute(_toRecaptchaAction(action), timeout: 10);
    return CaptchaChallenge(token: token, siteKey: siteKey);
  }

  String get _siteKey {
    if (Platform.isAndroid) {
      return ApiConstants.recaptchaAndroidSiteKey;
    }
    if (Platform.isIOS) {
      return ApiConstants.recaptchaIosSiteKey;
    }
    return '';
  }

  RecaptchaAction _toRecaptchaAction(CaptchaAction action) {
    return switch (action) {
      CaptchaAction.signup => RecaptchaAction.SIGNUP(),
      _ => RecaptchaAction.custom(action.value),
    };
  }
}
