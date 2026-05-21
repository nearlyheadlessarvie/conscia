import 'package:conscia_app/core/network/dio_client.dart';
import 'package:conscia_app/core/constants/api_constants.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/receipts/receipt_review_screen.dart';
import 'package:conscia_app/screens/transactions/widgets/transaction_style_category_selector.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/amount_hero_field.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpReceiptReviewScreen(
  WidgetTester tester, {
  Map<String, dynamic>? extractedData,
  String userCurrencyCode = 'USD',
}) async {
  SharedPreferences.setMockInitialValues(const {
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  });
  final prefs = await SharedPreferences.getInstance();

  final dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == ApiConstants.receipt('receipt-1')) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'ocrConfidence': 0.82,
                  'needsReview': true,
                  'extractedData': extractedData ??
                      {
                        'merchant': 'Corner Cafe',
                        'total': 18.50,
                        'currencyCode': 'USD',
                        'category': 'Dining',
                        'date': '2026-05-01T00:00:00.000Z',
                        'items': [
                          {'name': 'Latte', 'amount': 6.5},
                          {'name': 'Sandwich', 'amount': 12.0},
                        ],
                      },
                },
              ),
            );
            return;
          }

          handler.next(options);
        },
      ),
    );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dioProvider.overrideWithValue(dio),
        sharedPreferencesProvider.overrideWithValue(prefs),
        userPreferencesProvider.overrideWithValue(
          (currency: userCurrencyCode, locale: 'en_US'),
        ),
        subscriptionProvider.overrideWith(
          (ref) async => const SubscriptionStatus(
            tier: 'premium',
            isPremium: true,
          ),
        ),
        currentUserProvider.overrideWith(
          (ref) async => UserProfile(
            id: 'user-1',
            email: 'review@example.com',
            currencyCode: userCurrencyCode,
            locale: 'en_US',
            createdAt: DateTime(2026),
            hasCompletedOnboarding: true,
          ),
        ),
      ],
      child: const MaterialApp(
        home: ReceiptReviewScreen(receiptId: 'receipt-1'),
      ),
    ),
  );

  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('receipt review uses shared sections for extracted details',
      (tester) async {
    await _pumpReceiptReviewScreen(tester);

    expect(find.text('AI read quality'), findsOneWidget);
    expect(find.text('Transaction details'), findsOneWidget);
    expect(find.byType(AmountHeroField), findsOneWidget);
    expect(find.byType(TransactionStyleCategorySelector), findsOneWidget);
    expect(find.byKey(const ValueKey('receipt-review-confirm-dock')),
        findsOneWidget);
    expect(find.text('Confirm and save'), findsOneWidget);
    expect(find.text('Discard'), findsNothing);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('receipt-review-confirm-dock')),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(find.text('Latte'), findsOneWidget);
  });

  testWidgets('receipt review falls back to user currency when scan has none',
      (tester) async {
    await _pumpReceiptReviewScreen(
      tester,
      userCurrencyCode: 'PHP',
      extractedData: {
        'merchant': 'Unknown Merchant',
        'total': 0,
        'currencyCode': null,
        'category': null,
        'date': '2026-05-01T00:00:00.000Z',
        'items': <Map<String, Object?>>[],
      },
    );

    expect(find.text('PHP'), findsOneWidget);
    expect(find.text('USD'), findsNothing);
  });

  testWidgets('receipt review confirm dock stays close to keyboard',
      (tester) async {
    tester.view.physicalSize = const Size(450, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);

    await _pumpReceiptReviewScreen(tester);

    final dock = tester.getRect(
      find.byKey(const ValueKey('receipt-review-confirm-dock')),
    );

    expect(dock.bottom, greaterThan(660));
  });
}
