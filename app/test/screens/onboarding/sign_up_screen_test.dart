import 'package:conscia_app/screens/onboarding/sign_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign up screen does not show social auth buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SignUpScreen(),
        ),
      ),
    );

    expect(find.text('Sign up with Google'), findsNothing);
    expect(find.text('Sign up with Apple'), findsNothing);
    expect(find.text('Create Account'), findsNWidgets(2));
  });
}
