import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';

class AppAlert {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isDismissed;
  final DateTime createdAt;

  const AppAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isDismissed,
    required this.createdAt,
  });

  factory AppAlert.fromJson(Map<String, dynamic> json) {
    return AppAlert(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isDismissed: json['isDismissed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

final alertsDioProvider = Provider<Dio>((ref) {
  return ref.watch(dioProvider);
});

final alertsProvider = FutureProvider<List<AppAlert>>((ref) async {
  final dio = ref.watch(alertsDioProvider);
  try {
    final response = await dio.get(ApiConstants.alerts);
    final data = response.data as List;
    return data
        .map((e) => AppAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    rethrow;
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
        isDismissed: false,
        createdAt: now,
      ),
      ...state,
    ];
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
            isDismissed: true,
            createdAt: alert.createdAt,
          )
        else
          alert,
    ];
  }
}

final localAlertsProvider =
    StateNotifierProvider<LocalAlertsNotifier, List<AppAlert>>(
  (_) => LocalAlertsNotifier(),
);

final activeLocalAlertsProvider = Provider<List<AppAlert>>((ref) {
  final alerts = ref.watch(localAlertsProvider);
  return alerts.where((alert) => !alert.isDismissed).toList(growable: false);
});
