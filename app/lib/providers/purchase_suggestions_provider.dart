import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import 'transaction_providers.dart';

class PurchaseSuggestion {
  final String description;
  final double amount;
  final String currencyCode;
  final String category;
  final String frequencyLabel;

  const PurchaseSuggestion({
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.category,
    required this.frequencyLabel,
  });

  factory PurchaseSuggestion.fromJson(Map<String, dynamic> json) {
    return PurchaseSuggestion(
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      category: json['category'] as String,
      frequencyLabel: json['frequencyLabel'] as String,
    );
  }
}

final purchaseSuggestionsProvider =
    FutureProvider<List<PurchaseSuggestion>>((ref) async {
  // Re-fetches whenever the transaction list changes (new purchase → fresh suggestions)
  ref.watch(transactionListProvider);

  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<List<dynamic>>(ApiConstants.purchaseSuggestions);
    final data = response.data ?? [];
    return data
        .map((e) => PurchaseSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException {
    return [];
  }
});
