import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/services/transaction_service.dart';

Transaction makeTx(String category) => Transaction(
      id: 'id-$category-${DateTime.now().microsecondsSinceEpoch}',
      amount: 10,
      currencyCode: 'USD',
      category: category,
      description: 'desc',
      type: 'expense',
      date: DateTime.now(),
    );

void main() {
  group('categoryFrequencyProvider', () {
    test('returns top 5 categories sorted by frequency', () {
      final txs = [
        ...List.generate(5, (_) => makeTx('Coffee')),
        ...List.generate(3, (_) => makeTx('Dining')),
        ...List.generate(2, (_) => makeTx('Shopping')),
        makeTx('Gaming'),
        makeTx('Travel'),
        makeTx('Transport'),
      ];

      final container = ProviderContainer(overrides: [
        transactionListProvider
            .overrideWith((ref) => TransactionListNotifier.fromList(txs)),
      ]);
      addTearDown(container.dispose);

      final chips = container.read(categoryFrequencyProvider);

      expect(chips.first, 'Coffee');
      expect(chips[1], 'Dining');
      expect(chips[2], 'Shopping');
      expect(chips.length, 5);
    });

    test('falls back to static list when fewer than 5 distinct categories', () {
      final txs = [makeTx('Coffee'), makeTx('Coffee'), makeTx('Dining')];

      final container = ProviderContainer(overrides: [
        transactionListProvider
            .overrideWith((ref) => TransactionListNotifier.fromList(txs)),
      ]);
      addTearDown(container.dispose);

      final chips = container.read(categoryFrequencyProvider);

      expect(
          chips, containsAll(['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel']));
      expect(chips.length, 5);
    });
  });
}
