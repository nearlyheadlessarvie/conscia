import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/errors/app_error.dart';
import '../models/conscience_journey.dart';

class ConscienceJourneyService {
  final Dio _dio;

  ConscienceJourneyService(this._dio);

  Future<ConscienceJourneySummary> fetchJourney() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiConstants.conscienceJourney,
      );
      return ConscienceJourneySummary.fromJson(response.data ?? {});
    } catch (error, stackTrace) {
      throw AppError.from(error, stackTrace: stackTrace);
    }
  }

  Future<ConscienceJourneyUpdate> recordEvent({
    required String eventType,
    required String sourceId,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.conscienceJourneyEvents,
        data: {
          'eventType': eventType,
          'sourceId': sourceId,
        },
      );
      return ConscienceJourneyUpdate.fromJson(response.data ?? {});
    } catch (error, stackTrace) {
      throw AppError.from(error, stackTrace: stackTrace);
    }
  }
}
