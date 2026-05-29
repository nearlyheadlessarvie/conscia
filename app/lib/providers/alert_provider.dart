import 'dart:async';

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'message': message,
        'priority': priority,
        if (actionLabel != null) 'actionLabel': actionLabel,
        if (actionRoute != null) 'actionRoute': actionRoute,
        if (transactionId != null) 'transactionId': transactionId,
        if (category != null) 'category': category,
        if (counterparty != null) 'counterparty': counterparty,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  bool get isRecurringReminder => type == 'recurring_transaction_created';
}

final alertsDioProvider = Provider<Dio>((ref) {
  return ref.watch(dioProvider);
});

final alertActionsProvider = Provider<AlertActions>((ref) {
  final dio = ref.watch(alertsDioProvider);
  final authState = ref.watch(authProvider);
  return AlertActions(
    dio: dio,
    enabled: authState.isAuthenticated,
    onRemoteChanged: () => ref.invalidate(alertsProvider),
  );
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

class AlertActions {
  AlertActions({
    required Dio dio,
    required bool enabled,
    required void Function() onRemoteChanged,
  })  : _dio = dio,
        _enabled = enabled,
        _onRemoteChanged = onRemoteChanged;

  final Dio _dio;
  final bool _enabled;
  final void Function() _onRemoteChanged;

  Future<void> sync(AppAlert alert) async {
    if (!_enabled) return;
    try {
      await _dio.post(ApiConstants.alerts, data: alert.toJson());
      _onRemoteChanged();
    } catch (_) {
      // Local alerts remain useful even if the network is briefly unavailable.
    }
  }

  Future<void> dismiss(String id) async {
    if (!_enabled) return;
    try {
      await _dio.post(ApiConstants.alertDismiss(Uri.encodeComponent(id)));
      _onRemoteChanged();
    } catch (_) {
      // Dismiss locally first; the next successful call can refresh server state.
    }
  }
}

class LocalAlertsNotifier extends StateNotifier<List<AppAlert>> {
  LocalAlertsNotifier({
    Future<void> Function(AppAlert alert)? syncAlert,
    Future<void> Function(String id)? dismissRemote,
  })  : _syncAlert = syncAlert,
        _dismissRemote = dismissRemote,
        super(const []);

  final Future<void> Function(AppAlert alert)? _syncAlert;
  final Future<void> Function(String id)? _dismissRemote;

  void addBudgetNudge({required String category}) {
    final normalizedCategory = category.trim().toLowerCase();
    final alertId = 'budget-nudge-$normalizedCategory';
    if (state.any((alert) => alert.id == alertId)) {
      return;
    }

    final now = DateTime.now();
    final alert = AppAlert(
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
    );
    state = [alert, ...state];
    _sync(alert);
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
              'Your conscience journey reached a new level. A new milestone is ready.',
          priority: 75,
          actionLabel: 'View level',
          actionRoute: '/journey/level-up',
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
          actionLabel: 'See progress',
          actionRoute: '/',
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
          actionLabel: 'Continue journey',
          actionRoute: '/',
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
    for (final alert in newAlerts) {
      _sync(alert);
    }
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
    _dismiss(id);
  }

  void _sync(AppAlert alert) {
    final syncAlert = _syncAlert;
    if (syncAlert == null) return;
    unawaited(syncAlert(alert).catchError((_) {}));
  }

  void _dismiss(String id) {
    final dismissRemote = _dismissRemote;
    if (dismissRemote == null) return;
    unawaited(dismissRemote(id).catchError((_) {}));
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
    final actions = ref.watch(alertActionsProvider);
    return LocalAlertsNotifier(
      syncAlert: actions.sync,
      dismissRemote: actions.dismiss,
    );
  },
);

class DismissedAlertIdsNotifier extends StateNotifier<Set<String>> {
  DismissedAlertIdsNotifier({
    Future<void> Function(String id)? dismissRemote,
  })  : _dismissRemote = dismissRemote,
        super(const {});

  final Future<void> Function(String id)? _dismissRemote;

  void dismiss(String id) {
    state = {...state, id};
    final dismissRemote = _dismissRemote;
    if (dismissRemote == null) return;
    unawaited(dismissRemote(id).catchError((_) {}));
  }
}

final dismissedAlertIdsProvider =
    StateNotifierProvider<DismissedAlertIdsNotifier, Set<String>>(
  (ref) {
    ref.watch(authCacheScopeProvider);
    final actions = ref.watch(alertActionsProvider);
    return DismissedAlertIdsNotifier(dismissRemote: actions.dismiss);
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

  final seenIds = <String>{};
  final alerts = [
    for (final alert in [...remoteAlerts, ...localAlerts])
      if (seenIds.add(alert.id)) alert,
  ];
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
