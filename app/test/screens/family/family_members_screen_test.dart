import 'package:conscia_app/models/family_member.dart';
import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/screens/family/family_members_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('owner can manage non-owner family members', (tester) async {
    final actions = _RecordingFamilySpaceActions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceActionsProvider.overrideWithValue(actions),
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Owner',
            ),
          ),
          familyMembersProvider.overrideWith(
            (ref) async => [
              FamilyMember(
                id: 'member-owner',
                userId: 'user-owner',
                email: 'owner@example.com',
                role: 'Owner',
                joinedAt: DateTime(2026, 5),
                isCurrentUser: true,
              ),
              FamilyMember(
                id: 'member-spouse',
                userId: 'user-spouse',
                email: 'spouse@example.com',
                role: 'Contributor',
                joinedAt: DateTime(2026, 5, 2),
                isCurrentUser: false,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: FamilyMembersScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('owner@example.com'), findsOneWidget);
    expect(find.text('spouse@example.com'), findsOneWidget);
    expect(find.text('Contributor · Joined May 2'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    expect(find.byTooltip('More member actions'), findsOneWidget);
    expect(find.text('Make viewer'), findsNothing);

    await tester.tap(find.byTooltip('More member actions'));
    await tester.pumpAndSettle();
    expect(find.text('Make viewer'), findsOneWidget);
    expect(find.text('Transfer ownership'), findsOneWidget);
    expect(find.text('Remove from household'), findsOneWidget);

    await tester.tap(find.text('Make viewer'));
    await tester.pumpAndSettle();
    expect(actions.updatedMemberId, 'member-spouse');
    expect(actions.updatedRole, 'Viewer');
  });

  testWidgets('non-owner can leave but cannot manage members', (tester) async {
    final actions = _RecordingFamilySpaceActions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceActionsProvider.overrideWithValue(actions),
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Contributor',
            ),
          ),
          familyMembersProvider.overrideWith(
            (ref) async => [
              FamilyMember(
                id: 'member-me',
                userId: 'user-me',
                email: 'me@example.com',
                role: 'Contributor',
                joinedAt: DateTime(2026, 5, 2),
                isCurrentUser: true,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: FamilyMembersScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Manage'), findsNothing);
    expect(find.byTooltip('More member actions'), findsNothing);
    expect(find.text('Remove from household'), findsNothing);
    expect(find.text('Leave Family Space'), findsOneWidget);

    await tester.tap(find.text('Leave Family Space'));
    await tester.pumpAndSettle();
    expect(find.text('Leave Family Space?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Leave Family Space'));
    await tester.pumpAndSettle();
    expect(actions.leftFamily, isTrue);
  });

  testWidgets('owner can transfer ownership from member actions',
      (tester) async {
    final actions = _RecordingFamilySpaceActions();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          familySpaceActionsProvider.overrideWithValue(actions),
          familySpaceProvider.overrideWith(
            (ref) async => const FamilySpace(
              id: 'family-1',
              name: 'Santos Household',
              currencyCode: 'PHP',
              isReadOnly: false,
              role: 'Owner',
            ),
          ),
          familyMembersProvider.overrideWith(
            (ref) async => [
              FamilyMember(
                id: 'member-owner',
                userId: 'user-owner',
                email: 'owner@example.com',
                role: 'Owner',
                joinedAt: DateTime(2026, 5),
                isCurrentUser: true,
              ),
              FamilyMember(
                id: 'member-spouse',
                userId: 'user-spouse',
                email: 'spouse@example.com',
                role: 'Contributor',
                joinedAt: DateTime(2026, 5, 2),
                isCurrentUser: false,
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: FamilyMembersScreen()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More member actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Transfer ownership'));
    await tester.pumpAndSettle();
    expect(find.text('Transfer ownership?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Transfer ownership'));
    await tester.pumpAndSettle();

    expect(actions.transferredMemberId, 'member-spouse');
  });
}

class _RecordingFamilySpaceActions extends FamilySpaceActions {
  _RecordingFamilySpaceActions() : super();

  String? updatedMemberId;
  String? updatedRole;
  String? removedMemberId;
  String? transferredMemberId;
  bool leftFamily = false;

  @override
  Future<FamilyMember> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    updatedMemberId = memberId;
    updatedRole = role;
    return FamilyMember(
      id: memberId,
      userId: 'user-spouse',
      email: 'spouse@example.com',
      role: role,
      joinedAt: DateTime(2026, 5, 2),
      isCurrentUser: false,
    );
  }

  @override
  Future<void> removeMember(String memberId) async {
    removedMemberId = memberId;
  }

  @override
  Future<FamilyMember> transferOwnership(String memberId) async {
    transferredMemberId = memberId;
    return FamilyMember(
      id: memberId,
      userId: 'user-spouse',
      email: 'spouse@example.com',
      role: 'Owner',
      joinedAt: DateTime(2026, 5, 2),
      isCurrentUser: false,
    );
  }

  @override
  Future<void> leaveFamilySpace() async {
    leftFamily = true;
  }
}
