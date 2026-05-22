import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/usage_provider.dart';

abstract class LocationAssistanceService {
  Future<bool> isLocationServiceEnabled() async => true;
  Future<bool> requestPermission() async => false;
  Future<LocationPermissionStatus> checkPermissionStatus() async =>
      LocationPermissionStatus.denied;
  Future<bool> openAppSettings() async => false;
  Future<bool> openLocationSettings() async => false;

  Future<void> refreshLocationHint() async {}

  Future<void> recordTransactionContext({
    required String merchant,
    required String category,
  }) async {}

  ({List<String> nearbyMerchants, List<String> likelyCategories})
      getTransactionSuggestions();

  String? categoryForMerchant(String merchant) => null;
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
}

abstract class LocationGateway {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermissionStatus> checkPermission();

  Future<LocationPermissionStatus> requestPermission();

  Future<LocationCoordinate?> currentPosition();
}

class GeolocatorLocationGateway implements LocationGateway {
  const GeolocatorLocationGateway();

  @override
  Future<bool> isLocationServiceEnabled() =>
      geolocator.Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await geolocator.Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await geolocator.Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  @override
  Future<LocationCoordinate?> currentPosition() async {
    final position = await geolocator.Geolocator.getCurrentPosition(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.low,
      ),
    );
    return LocationCoordinate(position.latitude, position.longitude);
  }

  Future<bool> openAppSettings() => geolocator.Geolocator.openAppSettings();

  Future<bool> openLocationSettings() =>
      geolocator.Geolocator.openLocationSettings();

  LocationPermissionStatus _mapPermission(
    geolocator.LocationPermission permission,
  ) {
    return switch (permission) {
      geolocator.LocationPermission.always ||
      geolocator.LocationPermission.whileInUse =>
        LocationPermissionStatus.granted,
      geolocator.LocationPermission.deniedForever =>
        LocationPermissionStatus.deniedForever,
      geolocator.LocationPermission.denied ||
      geolocator.LocationPermission.unableToDetermine =>
        LocationPermissionStatus.denied,
    };
  }
}

class LocationCoordinate {
  const LocationCoordinate(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class LocalLocationAssistanceService implements LocationAssistanceService {
  const LocalLocationAssistanceService({
    this.prefs,
    this.locationGateway = const GeolocatorLocationGateway(),
  });

  static const _currentGeohashKey = 'smart_location_current_geohash';
  static const _merchantHistoryKey = 'smart_location_merchant_history';
  static const _geohashPrecision = 7;
  static const _maxHistoryEntries = 80;
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  final SharedPreferences? prefs;
  final LocationGateway locationGateway;

  @override
  Future<bool> isLocationServiceEnabled() =>
      locationGateway.isLocationServiceEnabled();

  @override
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    return locationGateway.checkPermission();
  }

  @override
  Future<bool> openAppSettings() => geolocator.Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() =>
      geolocator.Geolocator.openLocationSettings();

  @override
  Future<bool> requestPermission() async {
    if (!await locationGateway.isLocationServiceEnabled()) {
      return false;
    }

    var permission = await locationGateway.checkPermission();
    if (permission == LocationPermissionStatus.denied) {
      permission = await locationGateway.requestPermission();
    }

    if (permission != LocationPermissionStatus.granted) {
      return false;
    }

    unawaited(refreshLocationHint());
    return true;
  }

  @override
  Future<void> refreshLocationHint() async {
    final prefs = this.prefs;
    if (prefs == null) return;

    final position = await _currentPositionOrNull();
    if (position == null) return;

    await prefs.setString(
      _currentGeohashKey,
      _encodeGeohash(position, precision: _geohashPrecision),
    );
  }

  @override
  Future<void> recordTransactionContext({
    required String merchant,
    required String category,
  }) async {
    final prefs = this.prefs;
    final normalizedMerchant = merchant.trim();
    final normalizedCategory = category.trim();
    if (prefs == null ||
        normalizedMerchant.isEmpty ||
        normalizedCategory.isEmpty) {
      return;
    }

    final position = await _currentPositionOrNull();
    if (position == null) return;

    final geohash = _encodeGeohash(position, precision: _geohashPrecision);
    await prefs.setString(_currentGeohashKey, geohash);

    final history = _loadHistory();
    final normalizedKey = _normalizeMerchant(normalizedMerchant);
    final index = history.indexWhere(
      (entry) =>
          entry.geohash == geohash &&
          _normalizeMerchant(entry.merchant) == normalizedKey,
    );
    final now = DateTime.now().toUtc();
    if (index >= 0) {
      final current = history[index];
      history[index] = current.copyWith(
        merchant: normalizedMerchant,
        category: normalizedCategory,
        count: current.count + 1,
        lastUsedAt: now,
      );
    } else {
      history.add(
        _MerchantHistoryEntry(
          geohash: geohash,
          merchant: normalizedMerchant,
          category: normalizedCategory,
          count: 1,
          lastUsedAt: now,
        ),
      );
    }

    history.sort(_compareHistoryEntries);
    final bounded = history.take(_maxHistoryEntries).toList();
    await prefs.setString(
      _merchantHistoryKey,
      jsonEncode(bounded.map((entry) => entry.toJson()).toList()),
    );
  }

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
      getTransactionSuggestions() {
    final localSuggestions = _getLocalHistorySuggestions();
    return localSuggestions;
  }

  @override
  String? categoryForMerchant(String merchant) {
    return _categoryForLocalMerchant(merchant);
  }

  Future<LocationCoordinate?> _currentPositionOrNull() async {
    try {
      return await locationGateway.currentPosition();
    } catch (_) {
      return null;
    }
  }

  ({List<String> nearbyMerchants, List<String> likelyCategories})
      _getLocalHistorySuggestions() {
    final prefs = this.prefs;
    final currentGeohash = prefs?.getString(_currentGeohashKey);
    if (prefs == null || currentGeohash == null || currentGeohash.isEmpty) {
      return const (
        nearbyMerchants: <String>[],
        likelyCategories: <String>[],
      );
    }

    final ranked = _loadHistory()
        .where((entry) => entry.geohash == currentGeohash)
        .toList()
      ..sort(_compareHistoryEntries);

    final merchants = <String>[];
    final categories = <String>[];
    for (final entry in ranked) {
      if (!merchants.contains(entry.merchant)) {
        merchants.add(entry.merchant);
      }
      if (!categories.contains(entry.category)) {
        categories.add(entry.category);
      }
    }

    return (
      nearbyMerchants: merchants.take(5).toList(),
      likelyCategories: categories.take(4).toList(),
    );
  }

  String? _categoryForLocalMerchant(String merchant) {
    final prefs = this.prefs;
    final currentGeohash = prefs?.getString(_currentGeohashKey);
    if (prefs == null || currentGeohash == null) return null;

    final normalized = _normalizeMerchant(merchant);
    for (final entry in _loadHistory()) {
      if (entry.geohash == currentGeohash &&
          _normalizeMerchant(entry.merchant) == normalized) {
        return entry.category;
      }
    }
    return null;
  }

  List<_MerchantHistoryEntry> _loadHistory() {
    final raw = prefs?.getString(_merchantHistoryKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_MerchantHistoryEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  int _compareHistoryEntries(
    _MerchantHistoryEntry a,
    _MerchantHistoryEntry b,
  ) {
    final countComparison = b.count.compareTo(a.count);
    if (countComparison != 0) return countComparison;
    return b.lastUsedAt.compareTo(a.lastUsedAt);
  }

  String _normalizeMerchant(String merchant) => merchant.trim().toLowerCase();

  String _encodeGeohash(
    LocationCoordinate coordinate, {
    required int precision,
  }) {
    var latRange = (-90.0, 90.0);
    var lngRange = (-180.0, 180.0);
    var isLng = true;
    var bit = 0;
    var ch = 0;
    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (isLng) {
        final mid = (lngRange.$1 + lngRange.$2) / 2;
        if (coordinate.longitude >= mid) {
          ch = (ch << 1) + 1;
          lngRange = (mid, lngRange.$2);
        } else {
          ch <<= 1;
          lngRange = (lngRange.$1, mid);
        }
      } else {
        final mid = (latRange.$1 + latRange.$2) / 2;
        if (coordinate.latitude >= mid) {
          ch = (ch << 1) + 1;
          latRange = (mid, latRange.$2);
        } else {
          ch <<= 1;
          latRange = (latRange.$1, mid);
        }
      }

      isLng = !isLng;
      if (bit < 4) {
        bit += 1;
      } else {
        buffer.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }
}

class _MerchantHistoryEntry {
  const _MerchantHistoryEntry({
    required this.geohash,
    required this.merchant,
    required this.category,
    required this.count,
    required this.lastUsedAt,
  });

  final String geohash;
  final String merchant;
  final String category;
  final int count;
  final DateTime lastUsedAt;

  factory _MerchantHistoryEntry.fromJson(Map<String, dynamic> json) {
    return _MerchantHistoryEntry(
      geohash: json['geohash'] as String? ?? '',
      merchant: json['merchant'] as String? ?? '',
      category: json['category'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      lastUsedAt: DateTime.tryParse(json['lastUsedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  _MerchantHistoryEntry copyWith({
    String? merchant,
    String? category,
    int? count,
    DateTime? lastUsedAt,
  }) {
    return _MerchantHistoryEntry(
      geohash: geohash,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      count: count ?? this.count,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'geohash': geohash,
        'merchant': merchant,
        'category': category,
        'count': count,
        'lastUsedAt': lastUsedAt.toIso8601String(),
      };
}

final locationAssistanceServiceProvider =
    Provider<LocationAssistanceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalLocationAssistanceService(prefs: prefs);
});
