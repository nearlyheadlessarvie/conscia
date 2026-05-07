import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class LocationAssistanceService {
  Future<bool> requestPermission();

  ({List<String> nearbyMerchants, List<String> likelyCategories})
  getTransactionSuggestions();
}

class _UnsupportedLocationAssistanceService
    implements LocationAssistanceService {
  @override
  Future<bool> requestPermission() {
    throw UnimplementedError(
      'LocationAssistanceService.requestPermission must be provided by '
      'the app shell or a test override.',
    );
  }

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
  getTransactionSuggestions() {
    return const (
      nearbyMerchants: <String>[],
      likelyCategories: <String>[],
    );
  }
}

final locationAssistanceServiceProvider =
    Provider<LocationAssistanceService>((ref) {
  return _UnsupportedLocationAssistanceService();
});
