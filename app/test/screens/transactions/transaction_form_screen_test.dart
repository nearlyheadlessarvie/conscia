import 'package:conscia_app/providers/category_frequency_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/transactions/transaction_form_screen.dart';
import 'package:conscia_app/screens/transactions/widgets/quick_preset_chips.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('transaction form shows a single quick preset row when unselected', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryFrequencyProvider.overrideWithValue(
            ['Coffee', 'Dining', 'Shopping', 'Gaming', 'Travel'],
          ),
          subscriptionProvider.overrideWith(
            (ref) async => const SubscriptionStatus(
              tier: 'free',
              isPremium: false,
            ),
          ),
          currentUserProvider.overrideWith(
            (ref) async => UserProfile(
              id: 'user-1',
              email: 'tx@example.com',
              currencyCode: 'USD',
              locale: 'en_US',
              createdAt: DateTime(2026),
              hasCompletedOnboarding: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: TransactionFormScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(QuickPresetChips), findsOneWidget);
    expect(find.text('Quick add'), findsNothing);
  });
}
