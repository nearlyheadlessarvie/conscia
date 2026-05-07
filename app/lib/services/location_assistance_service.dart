import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class LocationAssistanceService {
  Future<bool> requestPermission();

  ({List<String> nearbyMerchants, List<String> likelyCategories})
  getTransactionSuggestions();
}

class LocalLocationAssistanceService
    implements LocationAssistanceService {
  @override
  Future<bool> requestPermission() async {
    // The app does not request OS location permission yet, so we treat
    // this as a local opt-in and keep suggestions best-effort.
    return true;
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
  return LocalLocationAssistanceService();
});
