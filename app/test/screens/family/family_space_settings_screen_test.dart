import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/app_availability_provider.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/screens/family/family_space_settings_screen.dart';
import 'package:conscia_app/services/api_availability_service.dart';
import 'package:conscia_app/services/app_update_service.dart';
import 'package:conscia_app/services/connectivity_service.dart';
import 'package:conscia_app/widgets/feed_card.dart';
import 'package:conscia_app/widgets/floating_label_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('family settings focuses on household management', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Owner',
            ),
          ),
        ],
        child: const MaterialApp(home: FamilySpaceSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('shared-conscia-hero')), findsOneWidget);
    expect(find.text('SHARED HOUSEHOLD'), findsOneWidget);
    expect(find.text('Plan together without exposing everything personal.'),
        findsOneWidget);
    expect(find.text('Owner'), findsWidgets);
    expect(find.text('PHP'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    expect(find.text('Members'), findsWidgets);
    expect(find.text('Invite family'), findsWidgets);
    expect(find.byType(FeedCard), findsNothing);
    expect(find.text('HOUSEHOLD'), findsOneWidget);
    expect(find.text('Household name'), findsOneWidget);
    expect(find.text('Santos Household'), findsWidgets);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('MANAGE'), findsOneWidget);
    expect(find.text('Family overview'), findsNothing);
    expect(find.text('Members'), findsWidgets);
    expect(find.text('Invites'), findsOneWidget);
    expect(find.text('Schedule contribution'), findsNothing);
    expect(find.text('Recent family activity'), findsNothing);
  });

  testWidgets('rename household sheet uses floating label input', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Owner',
            ),
          ),
        ],
        child: const MaterialApp(home: FamilySpaceSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Household name'));
    await tester.pumpAndSettle();

    final floatingFields = tester.widgetList<FloatingLabelTextField>(
      find.byType(FloatingLabelTextField),
    );

    expect(
      floatingFields.any((field) => field.label == 'Household name'),
      isTrue,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Household name',
      ),
      findsNothing,
    );
  });

  testWidgets('family settings hides household rename for non-owners', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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
        child: const MaterialApp(home: FamilySpaceSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Contributor'), findsWidgets);
    expect(find.text('Household name'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.text('Members'), findsWidgets);
    expect(find.text('Invites'), findsOneWidget);
    expect(find.text('Owner only'), findsOneWidget);
    expect(find.text('Import personal records'), findsNothing);
    expect(find.text('Schedule contribution'), findsNothing);
  });

  testWidgets('family settings explains read-only premium lock', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: true,
              role: 'Owner',
            ),
          ),
        ],
        child: const MaterialApp(home: FamilySpaceSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('View-only'), findsOneWidget);
    expect(
      find.text('Shared Conscia is view-only while Premium is inactive.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.edit_outlined), findsNothing);
    expect(find.text('Invites'), findsOneWidget);
    expect(find.text('Premium inactive'), findsWidgets);
  });

  testWidgets('family settings defers offline failures to global blocker', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appAvailabilityProvider.overrideWith(
            (ref) => _BlockedAppAvailabilityNotifier(),
          ),
          familySpaceProvider.overrideWith((ref) async {
            throw Exception('offline');
          }),
        ],
        child: const MaterialApp(home: FamilySpaceSettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unable to load Shared Conscia'), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });
}

class _BlockedAppAvailabilityNotifier extends AppAvailabilityNotifier {
  _BlockedAppAvailabilityNotifier()
      : super(
          connectivityService: _AlwaysConnectedService(),
          apiAvailabilityService: _HealthyApiService(),
          appUpdateService: _NoUpdateService(),
          autoRefresh: false,
          refreshOnInit: false,
        ) {
    state = AppAvailabilityState(
      issue: AvailabilityIssue.deviceOffline,
      lastChecked: DateTime(2026, 5, 19),
    );
  }
}

class _AlwaysConnectedService implements ConnectivityService {
  @override
  Future<bool> hasNetworkConnection() async => true;
}

class _HealthyApiService implements ApiAvailabilityService {
  @override
  Future<void> checkLiveness() async {}
}

class _NoUpdateService implements AppUpdateService {
  @override
  Future<AppUpdateCheckResult> checkForUpdate() async =>
      const AppUpdateCheckResult();
}
