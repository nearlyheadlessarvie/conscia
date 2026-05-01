import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  throw UnimplementedError('Override with Dio instance');
});

final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.getProfile();
});

final userPreferencesProvider = Provider<({String currency, String locale})>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.maybeWhen(
    data: (profile) => (currency: profile.currencyCode, locale: profile.locale),
    orElse: () => (currency: 'USD', locale: 'en_US'),
  );
});
