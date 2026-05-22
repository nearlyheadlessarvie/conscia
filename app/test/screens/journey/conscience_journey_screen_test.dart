import 'package:conscia_app/models/conscience_journey.dart';
import 'package:conscia_app/providers/auth_provider.dart';
import 'package:conscia_app/providers/conscience_journey_provider.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/screens/journey/conscience_journey_screen.dart';
import 'package:conscia_app/services/auth_service.dart';
import 'package:conscia_app/services/conscience_journey_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders journey progress, quests, and badges', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConscienceJourneyContent(summary: _summary()),
          ),
        ),
      ),
    );

    expect(find.text('Budget Guardian'), findsOneWidget);
    expect(find.text('85 / 600 XP to Conscience Captain'), findsOneWidget);
    expect(find.text("This week's quests"), findsOneWidget);
    expect(
      find.text('Habits to focus on this week. They reset every Sunday.'),
      findsOneWidget,
    );
    expect(find.text('Reflect on 3 purchases'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);
    expect(
      find.text('Badges earned by sticking to better money habits.'),
      findsOneWidget,
    );
    expect(find.text('First Reflection'), findsOneWidget);
    expect(find.text('???'), findsOneWidget);
    expect(find.text('6-day streak'), findsOneWidget);
    expect(find.text('MASCOT MOMENT'), findsNothing);
    expect(
      find.byKey(const ValueKey('journey-level-art-budget_guardian')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('journey-badge-art-first_reflection')),
      findsOneWidget,
    );
  });

  testWidgets('renders the iOS-forward sticky journey header', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            (ref) => _TestAuthNotifier(
              const AuthState(
                status: AuthStatus.authenticated,
                userId: 'user-1',
              ),
            ),
          ),
          conscienceJourneyServiceProvider
              .overrideWithValue(_StaticConscienceJourneyService()),
          familySpaceProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: ConscienceJourneyScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('journey-sticky-header')), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.byTooltip('Journey guide'), findsNothing);
    expect(find.text('Budget Guardian'), findsOneWidget);
  });
}

class _StaticConscienceJourneyService extends ConscienceJourneyService {
  _StaticConscienceJourneyService() : super(Dio());

  @override
  Future<ConscienceJourneySummary> fetchJourney() async => _summary();
}

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(Dio());
}

class _FakeSecureStorage extends FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
    AppleOptions? mOptions,
  }) async =>
      null;
}

class _TestAuthNotifier extends AuthNotifier {
  _TestAuthNotifier(AuthState initialState)
      : super(_FakeAuthService(), _FakeSecureStorage()) {
    state = initialState;
  }
}

ConscienceJourneySummary _summary() => ConscienceJourneySummary(
      xpTotal: 485,
      currentLevel: const ConscienceLevel(
        key: 'budget_guardian',
        title: 'Budget Guardian',
        requiredXp: 400,
      ),
      nextLevel: const ConscienceLevel(
        key: 'conscience_captain',
        title: 'Conscience Captain',
        requiredXp: 1000,
      ),
      xpIntoLevel: 85,
      xpToNextLevel: 515,
      momentumDays: 6,
      bestMomentumDays: 9,
      weeklyQuests: [
        ConscienceQuest(
          key: 'reflect_three_purchases',
          title: 'Reflect on 3 purchases',
          description: 'Turn recent decisions into useful signal.',
          progress: 3,
          target: 3,
          xpReward: 15,
          isCompleted: true,
          completedAt: DateTime.utc(2026, 5, 11),
        ),
      ],
      badges: [
        ConscienceBadge(
          key: 'first_reflection',
          title: 'First Reflection',
          description: 'Reflected on your first purchase.',
          progress: 1,
          target: 1,
          isUnlocked: true,
          unlockedAt: DateTime.utc(2026, 5, 1),
        ),
        const ConscienceBadge(
          key: 'budget_rescuer',
          title: 'Budget Rescuer',
          description: 'Created a budget from a nudge.',
          progress: 0,
          target: 1,
          isUnlocked: false,
        ),
      ],
      recentMascotMoment: ConscienceMascotMoment(
        key: 'pause_before_purchase',
        persona: 'both',
        title: 'You paused before buying.',
        message: 'Impulse and Reason both got a seat at the table.',
        createdAt: DateTime.utc(2026, 5, 11),
      ),
    );
