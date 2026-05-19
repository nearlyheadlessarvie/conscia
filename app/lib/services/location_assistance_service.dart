import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';

abstract class LocationAssistanceService {
  Future<bool> requestPermission();

  ({List<String> nearbyMerchants, List<String> likelyCategories})
      getTransactionSuggestions();

  String? categoryForMerchant(String merchant) => null;
}

class LocationCoordinate {
  const LocationCoordinate(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class LocalMerchantLocation {
  const LocalMerchantLocation({
    required this.merchant,
    required this.category,
    required this.coordinate,
    this.storyAffinity = 0,
  });

  final String merchant;
  final String category;
  final LocationCoordinate coordinate;
  final int storyAffinity;
}

class LocalLocationAssistanceService implements LocationAssistanceService {
  const LocalLocationAssistanceService({
    this.mockNearbyEnabled = false,
    this.currentLocation = _storyDemoCurrentLocation,
    this.radiusMeters = 1200,
    this.merchantLocations = _storyDemoMerchantLocations,
  });

  static const _storyDemoCurrentLocation = LocationCoordinate(
    14.5539,
    121.0192,
  );

  static const _storyDemoMerchantLocations = <LocalMerchantLocation>[
    LocalMerchantLocation(
      merchant: 'Starbucks',
      category: 'Dining',
      coordinate: LocationCoordinate(14.5542, 121.019),
      storyAffinity: 3,
    ),
    LocalMerchantLocation(
      merchant: 'Manam',
      category: 'Dining',
      coordinate: LocationCoordinate(14.5556, 121.021),
      storyAffinity: 3,
    ),
    LocalMerchantLocation(
      merchant: 'Landers',
      category: 'Groceries',
      coordinate: LocationCoordinate(14.5587, 121.0185),
      storyAffinity: 2,
    ),
    LocalMerchantLocation(
      merchant: 'Grab',
      category: 'Transportation',
      coordinate: LocationCoordinate(14.5516, 121.0168),
      storyAffinity: 2,
    ),
    LocalMerchantLocation(
      merchant: 'Wildflour',
      category: 'Dining',
      coordinate: LocationCoordinate(14.5615, 121.022),
      storyAffinity: 1,
    ),
    LocalMerchantLocation(
      merchant: 'OpenAI',
      category: 'Subscriptions',
      coordinate: LocationCoordinate(14.586, 121.063),
    ),
  ];

  final bool mockNearbyEnabled;
  final LocationCoordinate currentLocation;
  final double radiusMeters;
  final List<LocalMerchantLocation> merchantLocations;

  @override
  Future<bool> requestPermission() async {
    // The app does not request OS location permission yet, so we treat
    // this as a local opt-in and keep suggestions best-effort.
    return true;
  }

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
      getTransactionSuggestions() {
    if (!mockNearbyEnabled) {
      return const (
        nearbyMerchants: <String>[],
        likelyCategories: <String>[],
      );
    }

    final ranked = merchantLocations
        .map(
          (location) => (
            location: location,
            distanceMeters: _distanceMeters(
              currentLocation,
              location.coordinate,
            ),
          ),
        )
        .where((entry) => entry.distanceMeters <= radiusMeters)
        .toList()
      ..sort((a, b) {
        final aScore = a.distanceMeters - (a.location.storyAffinity * 100);
        final bScore = b.distanceMeters - (b.location.storyAffinity * 100);
        return aScore.compareTo(bScore);
      });

    final categories = <String>[];
    for (final entry in ranked) {
      if (!categories.contains(entry.location.category)) {
        categories.add(entry.location.category);
      }
    }

    return (
      nearbyMerchants: ranked.map((entry) => entry.location.merchant).toList(),
      likelyCategories: categories,
    );
  }

  @override
  String? categoryForMerchant(String merchant) {
    for (final location in merchantLocations) {
      if (location.merchant.toLowerCase() == merchant.toLowerCase()) {
        return location.category;
      }
    }
    return null;
  }

  double _distanceMeters(
    LocationCoordinate from,
    LocationCoordinate to,
  ) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = _degreesToRadians(from.latitude);
    final lat2 = _degreesToRadians(to.latitude);
    final deltaLat = _degreesToRadians(to.latitude - from.latitude);
    final deltaLng = _degreesToRadians(to.longitude - from.longitude);

    final haversine = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final centralAngle = 2 *
        math.atan2(
          math.sqrt(haversine),
          math.sqrt(1 - haversine),
        );

    return earthRadiusMeters * centralAngle;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
}

final locationAssistanceServiceProvider =
    Provider<LocationAssistanceService>((ref) {
  return LocalLocationAssistanceService(
    mockNearbyEnabled: ApiConstants.mockLocationSuggestions,
    currentLocation: LocationCoordinate(
      ApiConstants.mockLocationLatitude,
      ApiConstants.mockLocationLongitude,
    ),
    radiusMeters: ApiConstants.mockLocationRadiusMeters,
  );
});
