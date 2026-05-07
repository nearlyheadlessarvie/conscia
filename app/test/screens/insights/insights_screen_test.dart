import 'package:conscia_app/core/utils/currency_formatter.dart';
import 'package:conscia_app/models/insights_models.dart';
import 'package:conscia_app/providers/insights_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/insights/category_detail_screen.dart';
import 'package:conscia_app/screens/insights/insights_screen.dart';
import 'package:conscia_app/screens/insights/widgets/insights_formatting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('insights formatter falls back when locale is invalid', () {
    final formatted = formatInsightCurrency(
      42.5,
      currencyCode: 'USD',
      locale: 'bad_locale',
    );

    expect(
      formatted,
      CurrencyFormatter.format(42.5, currencyCode: 'USD'),
    );
  });

  testWidgets(
      'insights summary uses shared currency formatting instead of hardcoded pound text',
      (tester) async {
    final summary = InsightsSummary(
      regrettedAmount: 600,
      regrettedCategory: 'Dining',
      avgRegretRate: 0.42,
      patternCount: 3,
      updatedAt: DateTime(2026, 5, 8),
    );
    final expected = CurrencyFormatter.format(
      600,
      currencyCode: 'PHP',
      locale: 'en_PH',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider.overrideWithValue(
            (currency: 'PHP', locale: 'en_PH'),
          ),
          insightsSummaryProvider.overrideWith((ref) async => summary),
          insightsMerchantsProvider.overrideWith((ref) async => const []),
          insightsCategoriesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: InsightsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('£600'), findsNothing);
    expect(find.text(expected), findsOneWidget);
  });

  testWidgets(
      'category detail formats transaction amounts with a locale-safe shared formatter',
      (tester) async {
    final detail = CategoryDetail(
      stats: const CategoryStat(
        category: 'Dining',
        totalSpend: 240,
        regrettedSpend: 120,
        regretRate: 0.5,
        transactionCount: 4,
        projectedAnnual: 1440,
      ),
      recentTransactions: [
        TransactionSummary(
          id: 'tx-1',
          amount: 18.75,
          currencyCode: 'USD',
          category: 'Dining',
          merchant: 'Corner Cafe',
          date: DateTime(2026, 5, 1),
          regretLevel: 'regret',
        ),
      ],
    );
    final expected = CurrencyFormatter.format(18.75, currencyCode: 'USD');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesProvider.overrideWithValue(
            (currency: 'USD', locale: 'bad_locale'),
          ),
          categoryDetailProvider('Dining').overrideWith((ref) async => detail),
        ],
        child: const MaterialApp(
          home: CategoryDetailScreen(category: 'Dining'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('USD 18.75'), findsNothing);
    expect(find.text(expected), findsOneWidget);
  });
}
