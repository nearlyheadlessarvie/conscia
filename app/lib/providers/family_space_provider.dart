import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/constants/conscience_journey.dart';
import '../core/network/dio_client.dart';
import '../models/family_overview.dart';
import '../models/family_invite.dart';
import '../models/family_member.dart';
import '../models/family_space.dart';
import 'alert_provider.dart';
import 'auth_provider.dart';
import 'behavioral_insights_provider.dart';
import 'budget_providers.dart';
import 'conscience_journey_provider.dart';
import 'insight_feed_provider.dart';
import 'insights_provider.dart';
import 'transaction_providers.dart';

final familySpaceProvider = FutureProvider<FamilySpace?>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return null;
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familySpace);
  if (response.statusCode == 204 || response.data == null) return null;
  return FamilySpace.fromJson(Map<String, dynamic>.from(response.data as Map));
});

final selectedScopeProvider = StateProvider<String>((ref) {
  ref.watch(authCacheScopeProvider);
  return 'personal';
});

final familyOverviewProvider = FutureProvider<FamilyOverview>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) {
    return const FamilyOverview(
      familySpaceId: '',
      budgets: [],
      recentActivity: [],
      recurringItems: [],
    );
  }
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familyOverview);
  return FamilyOverview.fromJson(
    Map<String, dynamic>.from(response.data as Map),
  );
});

final familyInvitesProvider = FutureProvider<List<FamilyInvite>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return const [];
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
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return const [];
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familyOutgoingInvites);
  final data = response.data as List<dynamic>? ?? [];
  return data
      .map((item) =>
          FamilyInvite.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

final familyMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return const [];
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiConstants.familyMembers);
  final data = response.data as List<dynamic>? ?? [];
  return data
      .map((item) =>
          FamilyMember.fromJson(Map<String, dynamic>.from(item as Map)))
      .toList();
});

final familySpaceActionsProvider = Provider<FamilySpaceActions>((ref) {
  return FamilySpaceActions(ref);
});

void invalidateFamilyScopedProviders(Ref ref, {bool resetScope = false}) {
  if (resetScope) {
    ref.read(selectedScopeProvider.notifier).state = 'personal';
    ref.read(transactionScopeFilterProvider.notifier).state = 'personal';
  }

  ref.invalidate(familySpaceProvider);
  ref.invalidate(familyOverviewProvider);
  ref.invalidate(familyMembersProvider);
  ref.invalidate(familyInvitesProvider);
  ref.invalidate(familyOutgoingInvitesProvider);
  ref.invalidate(budgetListProvider);
  ref.invalidate(transactionListProvider);
  ref.invalidate(filteredTransactionListProvider);
  ref.invalidate(alertsProvider);
  ref.invalidate(behavioralInsightsProvider);
  ref.invalidate(insightsSummaryProvider);
  ref.invalidate(insightsCategoriesProvider);
  ref.invalidate(insightsMerchantsProvider);
  ref.invalidate(insightFeedProvider);
  ref.invalidate(dashboardInsightFeedProvider);
  ref.invalidate(dashboardInsightSummaryProvider);
}

class FamilySpaceActions {
  FamilySpaceActions([this._ref]);

  final Ref? _ref;

  Ref get _requireRef {
    final ref = _ref;
    if (ref == null) {
      throw StateError('FamilySpaceActions requires a Riverpod ref.');
    }
    return ref;
  }

  Future<FamilySpace> create({
    required String name,
    required String currencyCode,
  }) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    final response = await dio.post(
      ApiConstants.familySpace,
      data: {
        'name': name,
        'currencyCode': currencyCode,
      },
    );

    invalidateFamilyScopedProviders(ref);
    return FamilySpace.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<FamilySpace> updateName(String name) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    final response = await dio.put(
      ApiConstants.familySpace,
      data: {'name': name},
    );

    invalidateFamilyScopedProviders(ref);
    return FamilySpace.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> invite({
    required String email,
    required String role,
  }) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    await dio.post(
      ApiConstants.familyInvites,
      data: {
        'email': email,
        'role': role,
      },
    );
    _recordJourneyEvent(
      ref,
      ConscienceJourneyEvents.familyInviteSent,
      'family-invite:$email',
    );
    ref.invalidate(familyOutgoingInvitesProvider);
  }

  Future<void> acceptInvite(String inviteId) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    await dio.post(ApiConstants.familyInviteAccept(inviteId));
    invalidateFamilyScopedProviders(ref, resetScope: true);
  }

  Future<void> declineInvite(String inviteId) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    await dio.post(ApiConstants.familyInviteDecline(inviteId));
    ref.invalidate(familyInvitesProvider);
  }

  Future<void> cancelInvite(String inviteId) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    await dio.delete(ApiConstants.familyInvite(inviteId));
    ref.invalidate(familyOutgoingInvitesProvider);
  }

  Future<FamilyMember> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    final response = await dio.patch(
      ApiConstants.familyMemberRole(memberId),
      data: {'role': role},
    );

    invalidateFamilyScopedProviders(ref);
    return FamilyMember.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<FamilyMember> transferOwnership(String memberId) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    final response = await dio.post(
      ApiConstants.familyTransferOwnership(memberId),
    );

    invalidateFamilyScopedProviders(ref);
    return FamilyMember.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<void> removeMember(String memberId) async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    await dio.delete(ApiConstants.familyMember(memberId));
    invalidateFamilyScopedProviders(ref);
  }

  Future<void> leaveFamilySpace() async {
    final ref = _requireRef;
    final dio = ref.read(dioProvider);
    await dio.post(ApiConstants.familyLeave);
    invalidateFamilyScopedProviders(ref, resetScope: true);
  }
}

void _recordJourneyEvent(Ref ref, String eventType, String sourceId) {
  if (!ref.read(authProvider).isAuthenticated) return;
  unawaited(
    () async {
      try {
        await ref
            .read(conscienceJourneyProvider.notifier)
            .recordEvent(eventType: eventType, sourceId: sourceId);
      } catch (_) {
        // Family actions should succeed even if Journey progress is unavailable.
      }
    }(),
  );
}
