import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationSuggestionSet {
  final List<String> nearbyMerchants;
  final List<String> likelyCategories;

  const LocationSuggestionSet({
    required this.nearbyMerchants,
    required this.likelyCategories,
  });
}

abstract class LocationAssistanceService {
  Future<bool> requestPermission();

  LocationSuggestionSet getTransactionSuggestions();
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
  LocationSuggestionSet getTransactionSuggestions() {
    return const LocationSuggestionSet(
      nearbyMerchants: [
        'Blue Bottle Coffee',
        'Whole Foods Market',
        'Shell Station',
      ],
      likelyCategories: [
        'Coffee',
        'Dining',
        'Groceries',
      ],
    );
  }
}

final locationAssistanceServiceProvider =
    Provider<LocationAssistanceService>((ref) {
  return _UnsupportedLocationAssistanceService();
});
