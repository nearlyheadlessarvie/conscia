import 'package:conscia_app/widgets/recurring_schedule_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('shows cadence controls when recurring is enabled', (
    tester,
  ) async {
    DateTime? endDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecurringScheduleSection(
            enabled: true,
            cadence: 'Monthly',
            endDate: endDate,
            onEnabledChanged: (_) {},
            onCadenceChanged: (_) {},
            onEndDateChanged: (value) => endDate = value,
          ),
        ),
      ),
    );

    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Recurring'), findsOneWidget);
    expect(find.text('RECURRING'), findsNothing);
    expect(find.text('END DATE'), findsOneWidget);
    expect(find.text('Never ends'), findsWidgets);

    final title = tester.widget<Text>(find.text('Recurring'));
    final expected = GoogleFonts.libreBaskerville(
      textStyle: ThemeData().textTheme.titleLarge,
      fontWeight: FontWeight.w700,
    );
    expect(title.style?.fontFamily, expected.fontFamily);
  });
}
