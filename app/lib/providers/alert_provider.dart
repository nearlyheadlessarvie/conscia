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
