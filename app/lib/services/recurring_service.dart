import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../models/recurring_schedule.dart';

final recurringServiceProvider = Provider<RecurringService>((ref) {
  return RecurringService(ref.watch(dioProvider));
});

class RecurringService {
  final Dio _dio;

  RecurringService(this._dio);

  Future<List<RecurringSchedule>> list() async {
    final response = await _dio.get(ApiConstants.recurring);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => RecurringSchedule.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<RecurringSchedule> create(CreateRecurringScheduleRequest request) async {
    final response = await _dio.post(
      ApiConstants.recurring,
      data: request.toJson(),
    );
    return RecurringSchedule.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
