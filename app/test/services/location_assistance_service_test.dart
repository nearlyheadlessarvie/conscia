import 'dart:convert';

import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocationGateway implements LocationGateway {
  _FakeLocationGateway({
    this.permission = LocationPermissionStatus.granted,
    this.throwOnPosition = false,
  });

  bool serviceEnabled = true;
  LocationPermissionStatus permission;
  LocationCoordinate position = const LocationCoordinate(14.55391, 121.01921);
  bool throwOnPosition;
  int permissionRequests = 0;
  int positionRequests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermissionStatus> checkPermission() async => permission;

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    permissionRequests += 1;
    return permission;
  }

  @override
  Future<LocationCoordinate?> currentPosition() async {
    positionRequests += 1;
    if (throwOnPosition) {
      throw StateError('Location unavailable');
    }
    return position;
  }
}

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

    test('stores coarse geohash history without raw coordinates', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = LocalLocationAssistanceService(
        prefs: prefs,
        locationGateway: _FakeLocationGateway(),
      );

      await service.requestPermission();
      await service.recordTransactionContext(
        merchant: 'Wildflour',
        category: 'Dining',
      );

      final rawPrefs = prefs.getString('smart_location_merchant_history')!;
      final history = jsonDecode(rawPrefs) as List<dynamic>;
      final first = history.first as Map<String, dynamic>;
      expect(rawPrefs, contains('Wildflour'));
      expect(rawPrefs, contains('Dining'));
      expect(
          first['geohash'],
          isA<String>()
              .having((hash) => hash.length, 'small-area bucket precision', 7));
      expect(rawPrefs, isNot(contains('14.55391')));
      expect(rawPrefs, isNot(contains('121.01921')));
    });

    test('suggests merchants from local history in the current geohash bucket',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final gateway = _FakeLocationGateway();
      final service = LocalLocationAssistanceService(
        prefs: prefs,
        locationGateway: gateway,
      );

      await service.requestPermission();
      await service.recordTransactionContext(
        merchant: 'Wildflour',
        category: 'Dining',
      );
      await service.recordTransactionContext(
        merchant: 'Wildflour',
        category: 'Dining',
      );
      gateway.position = const LocationCoordinate(14.55395, 121.01925);
      await service.refreshLocationHint();

      final suggestions = service.getTransactionSuggestions();

      expect(suggestions.nearbyMerchants, ['Wildflour']);
      expect(suggestions.likelyCategories, ['Dining']);
      expect(service.categoryForMerchant('wildflour'), 'Dining');
    });

    test('does not suggest history from a different geohash bucket', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final gateway = _FakeLocationGateway();
      final service = LocalLocationAssistanceService(
        prefs: prefs,
        locationGateway: gateway,
      );

      await service.requestPermission();
      await service.recordTransactionContext(
        merchant: 'Wildflour',
        category: 'Dining',
      );
      gateway.position = const LocationCoordinate(14.63, 121.07);
      await service.refreshLocationHint();

      final suggestions = service.getTransactionSuggestions();

      expect(suggestions.nearbyMerchants, isEmpty);
      expect(suggestions.likelyCategories, isEmpty);
    });

    test('requestPermission returns false when location permission is denied',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final gateway = _FakeLocationGateway(
        permission: LocationPermissionStatus.denied,
      );
      final service = LocalLocationAssistanceService(
        prefs: prefs,
        locationGateway: gateway,
      );

      final granted = await service.requestPermission();

      expect(granted, isFalse);
      expect(gateway.permissionRequests, 1);
      expect(gateway.positionRequests, 0);
    });

    test('location lookup failures do not block transaction save', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = LocalLocationAssistanceService(
        prefs: prefs,
        locationGateway: _FakeLocationGateway(throwOnPosition: true),
      );

      await service.recordTransactionContext(
        merchant: 'Wildflour',
        category: 'Dining',
      );

      expect(prefs.getString('smart_location_merchant_history'), isNull);
    });
  });
}
