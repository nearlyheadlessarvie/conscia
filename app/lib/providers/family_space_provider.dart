import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/family_overview.dart';
import '../models/family_invite.dart';
import '../models/family_space.dart';

final familySpaceProvider = FutureProvider<FamilySpace?>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familySpace);
  if (response.statusCode == 204 || response.data == null) return null;
  return FamilySpace.fromJson(Map<String, dynamic>.from(response.data as Map));
});

final selectedScopeProvider = StateProvider<String>((ref) => 'personal');

final familyOverviewProvider = FutureProvider<FamilyOverview>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familyOverview);
  return FamilyOverview.fromJson(
    Map<String, dynamic>.from(response.data as Map),
  );
});

final familyInvitesProvider = FutureProvider<List<FamilyInvite>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familyInvites);
  final data = response.data as List<dynamic>? ?? [];
  return data
      .map((item) =>
          FamilyInvite.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

final familyOutgoingInvitesProvider =
    FutureProvider<List<FamilyInvite>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familyOutgoingInvites);
  final data = response.data as List<dynamic>? ?? [];
  return data
      .map((item) =>
          FamilyInvite.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

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
    _ref.invalidate(familyOverviewProvider);
    return FamilySpace.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<FamilySpace> updateName(String name) async {
    final dio = _ref.read(dioProvider);
    final response = await dio.put(
      ApiConstants.familySpace,
      data: {'name': name},
    );

    _ref.invalidate(familySpaceProvider);
    _ref.invalidate(familyOverviewProvider);
    return FamilySpace.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> invite({
    required String email,
    required String role,
  }) async {
    final dio = _ref.read(dioProvider);
    await dio.post(
      ApiConstants.familyInvites,
      data: {
        'email': email,
        'role': role,
      },
    );
    _ref.invalidate(familyOutgoingInvitesProvider);
  }

  Future<void> acceptInvite(String inviteId) async {
    final dio = _ref.read(dioProvider);
    await dio.post(ApiConstants.familyInviteAccept(inviteId));
    _ref.invalidate(familyInvitesProvider);
    _ref.invalidate(familySpaceProvider);
    _ref.invalidate(familyOverviewProvider);
  }

  Future<void> declineInvite(String inviteId) async {
    final dio = _ref.read(dioProvider);
    await dio.post(ApiConstants.familyInviteDecline(inviteId));
    _ref.invalidate(familyInvitesProvider);
  }

  Future<void> cancelInvite(String inviteId) async {
    final dio = _ref.read(dioProvider);
    await dio.delete(ApiConstants.familyInvite(inviteId));
    _ref.invalidate(familyOutgoingInvitesProvider);
  }

}
