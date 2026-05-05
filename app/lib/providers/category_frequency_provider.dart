import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'transaction_providers.dart';

const _staticFallback = ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'];

final categoryFrequencyProvider = Provider<List<String>>((ref) {
  final transactions = ref.watch(transactionListProvider).transactions;

  final counts = <String, int>{};
  for (final tx in transactions) {
    if (tx.category.isNotEmpty) {
      counts[tx.category] = (counts[tx.category] ?? 0) + 1;
    }
  }

  final distinct = counts.keys.toList();
  if (distinct.length < 5) return _staticFallback;

  final sorted = distinct
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

  return sorted.take(5).toList();
});
