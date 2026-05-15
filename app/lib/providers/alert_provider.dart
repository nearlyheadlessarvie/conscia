import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/conscience_journey.dart';
import 'auth_provider.dart';
import 'budget_providers.dart';

DateTime _parseAsUtc(String s) {
  final normalized = s.endsWith('Z') || s.contains('+') ? s : '${s}Z';
  return DateTime.parse(normalized).toLocal();
}

class AppAlert {
  final String id;
  final String type;
  final String title;
  final String message;
  final int priority;
  final String? actionLabel;
  final String? actionRoute;
  final String? transactionId;
  final String? category;
  final String? counterparty;
  final bool isDismissed;
  final DateTime createdAt;

  const AppAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.priority = 0,
    this.actionLabel,
    this.actionRoute,
    this.transactionId,
    this.category,
    this.counterparty,
    required this.isDismissed,
    required this.createdAt,
  });

  factory AppAlert.fromJson(Map<String, dynamic> json) {
    return AppAlert(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      actionLabel: json['actionLabel'] as String?,
      actionRoute: json['actionRoute'] as String?,
      transactionId: json['transactionId'] as String?,
      category: json['category'] as String?,
      counterparty: json['counterparty'] as String?,
      isDismissed: json['isDismissed'] as bool? ?? false,
      createdAt: _parseAsUtc(json['createdAt'] as String),
    );
  }

  bool get isRecurringReminder => type == 'recurring_transaction_created';
}

final alertsDioProvider = Provider<Dio>((ref) {
  return ref.watch(dioProvider);
});

final alertsProvider = FutureProvider<List<AppAlert>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isAuthenticated) return const [];
  final dio = ref.watch(alertsDioProvider);
  try {
    final response = await dio.get(ApiConstants.alerts);
    final data = response.data as List;
    return data
        .map((e) => AppAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return const [];
  }
});

class LocalAlertsNotifier extends StateNotifier<List<AppAlert>> {
  LocalAlertsNotifier() : super(const []);

  void addBudgetNudge({required String category}) {
    final normalizedCategory = category.trim().toLowerCase();
    final alertId = 'budget-nudge-$normalizedCategory';
    if (state.any((alert) => alert.id == alertId)) {
      return;
    }

    final now = DateTime.now();
    state = [
      AppAlert(
        id: alertId,
        type: 'budget_nudge',
        title: 'No budget for $category yet',
        message:
            'You logged an expense in $category without a matching budget. Add one in Settings whenever you are ready.',
        priority: 20,
        actionLabel: 'Add budget',
        actionRoute: '/settings/budgets',
        category: category,
        isDismissed: false,
        createdAt: now,
      ),
      ...state,
    ];
  }

  void addJourneyUpdate(ConscienceJourneyUpdate update) {
    if (update.wasDuplicate) return;

    final now = DateTime.now();
    final alerts = <AppAlert>[];

    if (update.leveledUp) {
      alerts.add(
        AppAlert(
          id: 'journey-level-${update.summary.currentLevel.key}',
          type: 'journey_level_up',
          title: 'Level up: ${update.summary.currentLevel.title}',
          message:
              'Your conscience journey reached a new level. The mascots noticed.',
          priority: 75,
          actionLabel: 'View journey',
          actionRoute: '/journey',
          isDismissed: false,
          createdAt: now,
        ),
      );
    }

    for (final badgeKey in update.unlockedBadgeKeys) {
      final badge = _findBadge(update.summary.badges, badgeKey);
      alerts.add(
        AppAlert(
          id: 'journey-badge-$badgeKey',
          type: 'journey_badge',
          title: 'Achievement unlocked',
          message: badge == null
              ? 'A new achievement joined your shelf.'
              : '${badge.title}: ${badge.description}',
          priority: 65,
          actionLabel: 'View achievements',
          actionRoute: '/journey',
          isDismissed: false,
          createdAt: now,
        ),
      );
    }

    for (final questKey in update.completedQuestKeys) {
      final quest = _findQuest(update.summary.weeklyQuests, questKey);
      alerts.add(
        AppAlert(
          id: 'journey-quest-$questKey',
          type: 'journey_quest',
          title: quest == null ? 'Quest complete' : 'Quest complete',
          message: quest == null
              ? 'One weekly quest is complete.'
              : '${quest.title} earned +${quest.xpReward} XP.',
          priority: 55,
          actionLabel: 'View quests',
          actionRoute: '/journey',
          isDismissed: false,
          createdAt: now,
        ),
      );
    }

    if (alerts.isEmpty) return;

    final existingIds = state.map((alert) => alert.id).toSet();
    final newAlerts = alerts
        .where((alert) => !existingIds.contains(alert.id))
        .toList(growable: false);
    if (newAlerts.isEmpty) return;

    state = [...newAlerts, ...state];
  }

  void dismiss(String id) {
    state = [
      for (final alert in state)
        if (alert.id == id)
          AppAlert(
            id: alert.id,
            type: alert.type,
            title: alert.title,
            message: alert.message,
            priority: alert.priority,
            actionLabel: alert.actionLabel,
            actionRoute: alert.actionRoute,
            transactionId: alert.transactionId,
            category: alert.category,
            counterparty: alert.counterparty,
            isDismissed: true,
            createdAt: alert.createdAt,
          )
        else
          alert,
    ];
  }

  ConscienceBadge? _findBadge(List<ConscienceBadge> badges, String key) {
    for (final badge in badges) {
      if (badge.key == key) return badge;
    }
    return null;
  }

  ConscienceQuest? _findQuest(List<ConscienceQuest> quests, String key) {
    for (final quest in quests) {
      if (quest.key == key) return quest;
    }
    return null;
  }
}

final localAlertsProvider =
    StateNotifierProvider<LocalAlertsNotifier, List<AppAlert>>(
  (ref) {
    ref.watch(authCacheScopeProvider);
    return LocalAlertsNotifier();
  },
);

class DismissedAlertIdsNotifier extends StateNotifier<Set<String>> {
  DismissedAlertIdsNotifier() : super(const {});

  void dismiss(String id) {
    state = {...state, id};
  }
}

final dismissedAlertIdsProvider =
    StateNotifierProvider<DismissedAlertIdsNotifier, Set<String>>(
  (ref) {
    ref.watch(authCacheScopeProvider);
    return DismissedAlertIdsNotifier();
  },
);

final activeAlertsProvider = Provider<List<AppAlert>>((ref) {
  final remoteAlerts = ref.watch(alertsProvider).valueOrNull ?? const [];
  final localAlerts = ref.watch(localAlertsProvider);
  final dismissedIds = ref.watch(dismissedAlertIdsProvider);
  final budgetCategories = ref
      .watch(budgetListProvider)
      .budgets
      .map((budget) => budget.category.trim().toLowerCase())
      .toSet();

  final alerts = [...remoteAlerts, ...localAlerts];
  final visibleAlerts = alerts.where((alert) {
    if (alert.isDismissed || dismissedIds.contains(alert.id)) return false;
    if (alert.type != 'budget_nudge') return true;

    final normalizedCategory = alert.id.startsWith('budget-nudge-')
        ? alert.id.substring('budget-nudge-'.length)
        : '';
    return !budgetCategories.contains(normalizedCategory);
  }).toList(growable: false);

  visibleAlerts.sort((a, b) {
    final priorityCompare = b.priority.compareTo(a.priority);
    if (priorityCompare != 0) return priorityCompare;
    return b.createdAt.compareTo(a.createdAt);
  });

  return visibleAlerts;
});
