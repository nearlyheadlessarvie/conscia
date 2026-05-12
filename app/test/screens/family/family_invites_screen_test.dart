import 'package:conscia_app/models/family_invite.dart';
import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/screens/family/family_invites_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('family invites screen shows pending invite actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyInvitesProvider.overrideWith(
            (ref) async => [
              FamilyInvite(
                id: 'invite-1',
                familySpaceId: 'family-1',
                familySpaceName: 'Santos Household',
                email: 'alice@example.com',
                role: 'Contributor',
                createdAt: DateTime(2026, 5, 1),
                expiresAt: DateTime(2026, 5, 15),
              ),
            ],
          ),
          familyOutgoingInvitesProvider.overrideWith((ref) async => []),
          familySpaceProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: FamilyInvitesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Family invites'), findsWidgets);
    expect(find.text('Invites you received'), findsOneWidget);
    expect(find.text('Santos Household'), findsOneWidget);
    expect(find.text('Contributor'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Accept'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Decline'), findsOneWidget);
  });

  testWidgets('family invites screen shows owner send-invite form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyInvitesProvider.overrideWith((ref) async => []),
          familyOutgoingInvitesProvider.overrideWith((ref) async => []),
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
        child: const MaterialApp(home: FamilyInvitesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Invite someone'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Send invite'), findsOneWidget);
  });

  testWidgets('empty invite sections use compact helper text', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familyInvitesProvider.overrideWith((ref) async => []),
          familyOutgoingInvitesProvider.overrideWith((ref) async => []),
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
        child: const MaterialApp(home: FamilyInvitesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No sent invites right now.'), findsOneWidget);
    expect(find.text('No pending invites right now.'), findsOneWidget);
    expect(find.text('No outstanding invites'), findsNothing);
    expect(find.text('No pending invites'), findsNothing);
  });

  testWidgets('owner sees outgoing invites and can cancel one', (
    tester,
  ) async {
    final actions = _RecordingFamilySpaceActions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceActionsProvider.overrideWithValue(actions),
          familyInvitesProvider.overrideWith((ref) async => []),
          familyOutgoingInvitesProvider.overrideWith(
            (ref) async => [
              FamilyInvite(
                id: 'invite-outgoing',
                familySpaceId: 'family-1',
                familySpaceName: 'Santos Household',
                email: 'wife@example.com',
                role: 'Contributor',
                createdAt: DateTime(2026, 5, 1),
                expiresAt: DateTime(2026, 5, 15),
              ),
            ],
          ),
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
        child: const MaterialApp(home: FamilyInvitesScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Invites you sent'), findsOneWidget);
    expect(find.text('wife@example.com'), findsOneWidget);
    expect(
        find.widgetWithText(OutlinedButton, 'Cancel invite'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel invite'));
    await tester.pumpAndSettle();

    expect(actions.cancelledInviteIds, ['invite-outgoing']);
  });
}

class _RecordingFamilySpaceActions implements FamilySpaceActions {
  final cancelledInviteIds = <String>[];

  @override
  Future<void> cancelInvite(String inviteId) async {
    cancelledInviteIds.add(inviteId);
  }

  @override
  Future<void> acceptInvite(String inviteId) async {}

  @override
  Future<FamilySpace> create({
    required String name,
    required String currencyCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> declineInvite(String inviteId) async {}

  @override
  Future<void> invite({
    required String email,
    required String role,
  }) async {}

  @override
  Future<FamilySpace> updateName(String name) {
    throw UnimplementedError();
  }
}
