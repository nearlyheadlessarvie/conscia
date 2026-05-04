import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';

/// Returns the live exchange rate for [from] → [to].
/// Returns null on error or when currencies are the same.
final exchangeRateProvider =
    FutureProvider.family<double?, (String from, String to)>((ref, pair) async {
  final (from, to) = pair;
  if (from == to) return null;
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
      'exchange-rates/$from/$to',
    );
    final rate = response.data?['rate'];
    if (rate is num) return rate.toDouble();
    return null;
  } on DioException {
    return null;
  }
});
