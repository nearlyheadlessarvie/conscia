import 'dart:async';
import 'dart:convert';

import 'package:conscia_app/services/transaction_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('list sends and parses pagination cursor', () async {
    final adapter = _RecordingAdapter((options, _) {
      expect(options.method, 'GET');
      expect(options.path, 'transactions');
      expect(options.queryParameters['nextToken'], 'cursor-1');

      return ResponseBody.fromString(
        jsonEncode({
          'items': [],
          'totalCount': 0,
          'page': 1,
          'pageSize': 20,
          'hasMore': true,
          'nextToken': 'cursor-2',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api/'))
      ..httpClientAdapter = adapter;

    final result = await TransactionService(dio).list(nextToken: 'cursor-1');

    expect(result.nextToken, 'cursor-2');
    expect(result.hasMore, true);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._handler);

  final ResponseBody Function(RequestOptions options, List<int> bytes) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bytes = requestStream == null
        ? <int>[]
        : await requestStream.expand((chunk) => chunk).toList();
    return _handler(options, bytes);
  }

  @override
  void close({bool force = false}) {}
}
