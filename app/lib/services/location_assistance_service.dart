import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class LocationAssistanceService {
  Future<bool> requestPermission();
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
}

final locationAssistanceServiceProvider =
    Provider<LocationAssistanceService>((ref) {
  return _UnsupportedLocationAssistanceService();
});
