import 'package:conscia_app/core/network/dio_client.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/receipts/receipt_review_screen.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpReceiptReviewScreen(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(const {
    'location_suggestions_enabled': false,
    'location_suggestions_prompted': true,
  });
  final prefs = await SharedPreferences.getInstance();

  final dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/receipts/receipt-1') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'ocrConfidence': 0.82,
                  'needsReview': true,
                  'extractedData': {
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
            currencyCode: 'USD',
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

    expect(find.text('AI READ QUALITY'), findsOneWidget);
    expect(find.text('TRANSACTION DETAILS'), findsOneWidget);
    expect(find.text('Confirm and save'), findsOneWidget);
    expect(find.text('Latte'), findsOneWidget);
  });
}
