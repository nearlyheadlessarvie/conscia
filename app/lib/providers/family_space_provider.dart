import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/family_space.dart';

final familySpaceProvider = FutureProvider<FamilySpace?>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familySpace);
  if (response.statusCode == 204 || response.data == null) return null;
  return FamilySpace.fromJson(Map<String, dynamic>.from(response.data as Map));
});

final selectedScopeProvider = StateProvider<String>((ref) => 'personal');

final familySpaceActionsProvider = Provider<FamilySpaceActions>((ref) {
  return FamilySpaceActions(ref);
});

class FamilySpaceActions {
  FamilySpaceActions(this._ref);

  final Ref _ref;

  Future<FamilySpace> create({
    required String name,
    required String currencyCode,
  }) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.post(
      ApiConstants.familySpace,
      data: {
        'name': name,
        'currencyCode': currencyCode,
      },
    );

    _ref.invalidate(familySpaceProvider);
    return FamilySpace.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
