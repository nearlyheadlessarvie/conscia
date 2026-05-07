import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationAssistanceService {
  Future<bool> requestPermission() async {
    throw UnimplementedError(
      'LocationAssistanceService.requestPermission must be overridden '
      'with a platform-specific implementation.',
    );
  }
}

final locationAssistanceServiceProvider =
    Provider<LocationAssistanceService>((ref) {
  return LocationAssistanceService();
});
