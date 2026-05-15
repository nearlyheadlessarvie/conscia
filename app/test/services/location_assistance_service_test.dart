import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocalLocationAssistanceService', () {
    test('returns no suggestions when local mock nearby is disabled', () {
      const service = LocalLocationAssistanceService();

      final suggestions = service.getTransactionSuggestions();

      expect(suggestions.nearbyMerchants, isEmpty);
      expect(suggestions.likelyCategories, isEmpty);
    });

    test('filters mock merchants by distance from the mock location', () {
      const service = LocalLocationAssistanceService(
        mockNearbyEnabled: true,
        currentLocation: LocationCoordinate(14, 121),
        radiusMeters: 500,
        merchantLocations: [
          LocalMerchantLocation(
            merchant: 'Starbucks',
            category: 'Dining',
            coordinate: LocationCoordinate(14.0005, 121.0005),
          ),
          LocalMerchantLocation(
            merchant: 'OpenAI',
            category: 'Subscriptions',
            coordinate: LocationCoordinate(14.02, 121.02),
          ),
        ],
      );

      final suggestions = service.getTransactionSuggestions();

      expect(suggestions.nearbyMerchants, ['Starbucks']);
      expect(suggestions.likelyCategories, ['Dining']);
    });

    test('ranks nearby merchants by distance plus story relevance', () {
      const service = LocalLocationAssistanceService(
        mockNearbyEnabled: true,
        currentLocation: LocationCoordinate(14, 121),
        radiusMeters: 500,
        merchantLocations: [
          LocalMerchantLocation(
            merchant: 'Corner Store',
            category: 'Groceries',
            coordinate: LocationCoordinate(14.0001, 121.0001),
          ),
          LocalMerchantLocation(
            merchant: 'Manam',
            category: 'Dining',
            coordinate: LocationCoordinate(14.0006, 121.0006),
            storyAffinity: 3,
          ),
        ],
      );

      final suggestions = service.getTransactionSuggestions();

      expect(suggestions.nearbyMerchants, ['Manam', 'Corner Store']);
      expect(suggestions.likelyCategories, ['Dining', 'Groceries']);
    });

    test('resolves a nearby merchant category from location metadata', () {
      const service = LocalLocationAssistanceService(
        mockNearbyEnabled: true,
        merchantLocations: [
          LocalMerchantLocation(
            merchant: 'Corner Store',
            category: 'Groceries',
            coordinate: LocationCoordinate(14.0001, 121.0001),
          ),
        ],
      );

      expect(service.categoryForMerchant('corner store'), 'Groceries');
      expect(service.categoryForMerchant('Unknown'), isNull);
    });

    test('ships with a story-demo mock fixture for local testing', () {
      const service = LocalLocationAssistanceService(mockNearbyEnabled: true);

      final suggestions = service.getTransactionSuggestions();

      expect(
        suggestions.nearbyMerchants,
        containsAll(['Starbucks', 'Manam', 'Landers']),
      );
      expect(
        suggestions.likelyCategories,
        containsAll(['Dining', 'Groceries', 'Transportation']),
      );
    });
  });
}
