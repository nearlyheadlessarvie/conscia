import 'package:conscia_app/widgets/grouped_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GroupedListCard inserts separators between children',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GroupedListCard(
            children: [
              Text('One'),
              Text('Two'),
              Text('Three'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.byType(Divider), findsNWidgets(2));
  });
}
