import 'package:conscia_app/core/network/dio_client.dart';
import 'package:conscia_app/screens/settings/service_status_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('service status renders service checks when available',
      (tester) async {
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'status': 'Healthy',
                  'totalDuration': '12ms',
                  'checks': [
                    {
                      'name': 'api',
                      'status': 'Healthy',
                      'duration': '10ms',
                    },
                    {
                      'name': 'ai',
                      'status': 'Degraded',
                      'duration': '50ms',
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
        ],
        child: const MaterialApp(
          home: ServiceStatusScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('All Systems Operational'), findsOneWidget);
    expect(find.text('API Server'), findsOneWidget);
    expect(find.text('AI Service'), findsOneWidget);
    expect(find.text('Response: 10ms'), findsOneWidget);
    expect(find.text('Response: 50ms'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);
    expect(find.byType(RefreshIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
