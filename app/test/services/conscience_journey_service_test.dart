import 'dart:convert';
import 'dart:typed_data';

import 'package:conscia_app/core/constants/api_constants.dart';
import 'package:conscia_app/core/errors/app_error.dart';
import 'package:conscia_app/services/conscience_journey_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AppError.resetForTests);

  test('fetchJourney decodes the journey summary', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'))
      ..httpClientAdapter = _JsonAdapter((options) {
        expect(options.method, 'GET');
        expect(options.path, ApiConstants.conscienceJourney);
        return _jsonResponse(_summaryJson());
      });
    final service = ConscienceJourneyService(dio);

    final summary = await service.fetchJourney();

    expect(summary.xpTotal, 125);
    expect(summary.currentLevel.key, 'impulse_spotter');
    expect(summary.weeklyQuests.single.key, 'reflect_three_purchases');
  });

  test('recordEvent posts idempotent event data and decodes the update',
      () async {
    Map<String, dynamic>? capturedBody;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'))
      ..httpClientAdapter = _JsonAdapter((options) {
        expect(options.method, 'POST');
        expect(options.path, ApiConstants.conscienceJourneyEvents);
        capturedBody = options.data as Map<String, dynamic>;
        return _jsonResponse({
          'summary': _summaryJson(xpTotal: 145),
          'xpAwarded': 20,
          'wasDuplicate': false,
          'leveledUp': false,
          'completedQuestKeys': <String>[],
          'unlockedBadgeKeys': ['first_reflection'],
          'mascotMoment': null,
        });
      });
    final service = ConscienceJourneyService(dio);

    final update = await service.recordEvent(
      eventType: 'reflection_completed',
      sourceId: 'tx-123',
    );

    expect(capturedBody, {
      'eventType': 'reflection_completed',
      'sourceId': 'tx-123',
    });
    expect(update.xpAwarded, 20);
    expect(update.summary.xpTotal, 145);
    expect(update.unlockedBadgeKeys, ['first_reflection']);
  });

  test('service maps Dio failures to AppError', () async {
    AppError.configure(
      referenceIdFactory: () => 'REF12345',
      logger: (_) {},
    );
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/'))
      ..httpClientAdapter = _JsonAdapter((_) {
        return ResponseBody.fromString('server sad', 500);
      });
    final service = ConscienceJourneyService(dio);

    await expectLater(
      service.fetchJourney(),
      throwsA(
        isA<AppError>().having(
          (error) => error.userMessage,
          'userMessage',
          contains('REF12345'),
        ),
      ),
    );
  });
}

Map<String, dynamic> _summaryJson({int xpTotal = 125}) => {
      'xpTotal': xpTotal,
      'currentLevel': {
        'key': 'impulse_spotter',
        'title': 'Impulse Spotter',
        'requiredXp': 120,
      },
      'nextLevel': {
        'key': 'budget_guardian',
        'title': 'Budget Guardian',
        'requiredXp': 400,
      },
      'xpIntoLevel': 25,
      'xpToNextLevel': 275,
      'momentumDays': 4,
      'bestMomentumDays': 6,
      'weeklyQuests': [
        {
          'key': 'reflect_three_purchases',
          'title': 'Reflect on 3 purchases',
          'description': 'Turn recent decisions into useful signal.',
          'progress': 1,
          'target': 3,
          'xpReward': 15,
          'isCompleted': false,
          'completedAt': null,
        }
      ],
      'badges': <Map<String, dynamic>>[],
      'recentMascotMoment': null,
    };

ResponseBody _jsonResponse(Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this._handler);

  final ResponseBody Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return _handler(options);
  }
}
