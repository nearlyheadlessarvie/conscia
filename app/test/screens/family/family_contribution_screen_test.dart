import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/models/recurring_schedule.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/screens/family/family_contribution_screen.dart';
import 'package:conscia_app/services/recurring_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('family contribution screen schedules family income recurring item',
      (tester) async {
    final service = _RecordingRecurringService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recurringServiceProvider.overrideWithValue(service),
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Contributor',
            ),
          ),
        ],
        child: const MaterialApp(home: FamilyContributionScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '15000');
    await tester.enterText(
      find.widgetWithText(TextField, 'Contribution label'),
      'Payroll share',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Schedule contribution'));
    await tester.pumpAndSettle();

    expect(service.created?.type, 'income');
    expect(service.created?.amount, 15000);
    expect(service.created?.currencyCode, 'PHP');
    expect(service.created?.category, 'Family Contribution');
    expect(service.created?.counterparty, 'Payroll share');
    expect(service.created?.scope, 'family');
    expect(service.created?.familySpaceId, 'family-1');
  });
}

class _RecordingRecurringService extends RecurringService {
  _RecordingRecurringService() : super(Dio());

  CreateRecurringScheduleRequest? created;

  @override
  Future<RecurringSchedule> create(CreateRecurringScheduleRequest request) async {
    created = request;
    return RecurringSchedule(
      id: 'schedule-1',
      type: request.type,
      amount: request.amount,
      currencyCode: request.currencyCode,
      category: request.category,
      counterparty: request.counterparty,
      cadence: request.cadence,
      startDate: request.startDate,
      nextRunAt: request.startDate,
      isActive: true,
    );
  }
}
