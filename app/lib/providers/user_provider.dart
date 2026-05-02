import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/currencies.dart';
import '../core/network/dio_client.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(dioProvider));
});

final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.getProfile();
});

({String currency, String locale}) deviceDefaults() {
  final deviceLocale = ui.PlatformDispatcher.instance.locale;
  final country = deviceLocale.countryCode ?? 'US';
  return (
    currency: Currencies.fromCountry(country),
    locale: '${deviceLocale.languageCode}_$country',
  );
}

final userPreferencesProvider = Provider<({String currency, String locale})>((ref) {
  final user = ref.watch(currentUserProvider);
  final defaults = deviceDefaults();
  return user.maybeWhen(
    data: (profile) => (currency: profile.currencyCode, locale: profile.locale),
    orElse: () => defaults,
  );
});
