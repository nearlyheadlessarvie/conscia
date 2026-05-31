import 'package:conscia_app/models/family_space.dart';
import 'package:conscia_app/providers/admin_entitlement_provider.dart';
import 'package:conscia_app/providers/family_space_provider.dart';
import 'package:conscia_app/providers/location_assistance_provider.dart';
import 'package:conscia_app/providers/passkey_provider.dart';
import 'package:conscia_app/providers/subscription_provider.dart';
import 'package:conscia_app/providers/transaction_providers.dart';
import 'package:conscia_app/providers/usage_provider.dart';
import 'package:conscia_app/providers/user_provider.dart';
import 'package:conscia_app/screens/settings/settings_screen.dart';
import 'package:conscia_app/services/location_assistance_service.dart';
import 'package:conscia_app/services/passkey_service.dart';
import 'package:conscia_app/services/subscription_service.dart';
import 'package:conscia_app/services/transaction_service.dart';
import 'package:conscia_app/services/user_service.dart';
import 'package:conscia_app/widgets/hero_shortcut_card.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingLocationAssistanceService extends LocationAssistanceService {
  _RecordingLocationAssistanceService({
    required this.permissionGranted,
    this.locationServiceEnabled = true,
    this.permissionStatus = LocationPermissionStatus.denied,
  });

  final bool permissionGranted;
  final bool locationServiceEnabled;
  final LocationPermissionStatus permissionStatus;
  int permissionRequests = 0;
  int openAppSettingsCalls = 0;
  int openLocationSettingsCalls = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => locationServiceEnabled;

  @override
  Future<bool> requestPermission() async {
    permissionRequests += 1;
    return permissionGranted;
  }

  @override
  Future<LocationPermissionStatus> checkPermissionStatus() async {
    if (permissionRequests > 0 && permissionGranted) {
      return LocationPermissionStatus.granted;
    }
    return permissionStatus;
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls += 1;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls += 1;
    return true;
  }

  @override
  ({List<String> nearbyMerchants, List<String> likelyCategories})
      getTransactionSuggestions() {
    return const (
      nearbyMerchants: <String>[],
      likelyCategories: <String>[],
    );
  }
}

class _RecordingUserService extends UserService {
  _RecordingUserService() : super(Dio());

  String? lastLocale;
  String? lastAiPersonalityIntensity;

  @override
  Future<UserProfile> updateProfile({
    String? preferredCurrency,
    String? locale,
    String? displayName,
    String? profilePictureKey,
    String? photoUrl,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
    String? aiPersonalityIntensity,
  }) async {
    lastLocale = locale;
    lastAiPersonalityIntensity = aiPersonalityIntensity;
    return UserProfile(
      id: 'user-1',
      email: 'settings@example.com',
      currencyCode: preferredCurrency ?? 'USD',
      locale: locale ?? 'en_US',
      createdAt: DateTime(2026),
      hasCompletedOnboarding: true,
      aiPersonalityIntensity: aiPersonalityIntensity ?? 'balanced',
    );
  }
}

class _FailingCurrencyUserService extends _RecordingUserService {
  @override
  Future<UserProfile> updateProfile({
    String? preferredCurrency,
    String? locale,
    String? displayName,
    String? profilePictureKey,
    String? photoUrl,
    String? spendingPersonality,
    String? incomeRange,
    String? occupationType,
    String? householdSize,
    bool? hasCompletedOnboarding,
    String? aiPersonalityIntensity,
  }) async {
    if (preferredCurrency != null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/users/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/users/me'),
          statusCode: 409,
          data: const {
            'error': 'Default currency is locked after your first transaction.',
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }

    return super.updateProfile(
      preferredCurrency: preferredCurrency,
      locale: locale,
      displayName: displayName,
      profilePictureKey: profilePictureKey,
      photoUrl: photoUrl,
      spendingPersonality: spendingPersonality,
      incomeRange: incomeRange,
      occupationType: occupationType,
      householdSize: householdSize,
      hasCompletedOnboarding: hasCompletedOnboarding,
      aiPersonalityIntensity: aiPersonalityIntensity,
    );
  }
}

class _RecordingPasskeyService extends PasskeyService {
  _RecordingPasskeyService()
      : super(
          publicDio: Dio(),
          authenticatedDio: Dio(),
        );

  int registerCount = 0;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<String?> registerCurrentUserPasskey() async {
    registerCount += 1;
    return 'device-credential-id';
  }
}

Future<ProviderContainer> _pumpSettingsScreen(
  WidgetTester tester, {
  required SharedPreferences prefs,
  required LocationAssistanceService locationService,
  UserService? userService,
  FamilySpace? familySpace,
  List<Transaction>? transactions,
  bool isPremium = false,
  PageStorageBucket? pageStorageBucket,
  List<Override> overrides = const [],
}) async {
  final container = ProviderContainer(
    overrides: [
      currentUserProvider.overrideWith(
        (ref) async => UserProfile(
          id: 'user-1',
          email: 'settings@example.com',
          currencyCode: 'USD',
          locale: 'en_US',
          createdAt: DateTime(2026),
          hasCompletedOnboarding: true,
          aiPersonalityIntensity: 'balanced',
        ),
      ),
      familySpaceProvider.overrideWith((ref) async => familySpace),
      subscriptionProvider.overrideWith(
        (ref) async => SubscriptionStatus(
          tier: isPremium ? 'premium' : 'free',
          isPremium: isPremium,
        ),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      locationAssistanceServiceProvider.overrideWithValue(locationService),
      if (userService != null)
        userServiceProvider.overrideWithValue(userService),
      if (transactions != null)
        transactionListProvider.overrideWith(
          (ref) => TransactionListNotifier.fromList(transactions),
        ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: PageStorage(
          bucket: pageStorageBucket ?? PageStorageBucket(),
          child: const SettingsScreen(),
        ),
      ),
    ),
  );

  return container;
}

Future<void> _pumpWithContainer(
  WidgetTester tester,
  ProviderContainer container,
  PageStorageBucket bucket,
  Widget child,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: PageStorage(bucket: bucket, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets('settings app bar syncs after restored scroll position', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final bucket = PageStorageBucket();
    final container = await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService:
          _RecordingLocationAssistanceService(permissionGranted: true),
      pageStorageBucket: bucket,
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -180));
    await tester.pumpAndSettle();

    await _pumpWithContainer(
      tester,
      container,
      bucket,
      const Scaffold(body: Text('Other screen')),
    );
    await tester.pumpAndSettle();

    await _pumpWithContainer(
      tester,
      container,
      bucket,
      const SettingsScreen(),
    );
    await tester.pumpAndSettle();

    final capsule = tester.widget<Container>(
      find.byKey(const ValueKey('conscia-app-bar-capsule')),
    );
    final decoration = capsule.decoration! as BoxDecoration;

    expect(decoration.color, isNot(Colors.transparent));
  });

  testWidgets('settings version footer keeps only safe breathing room', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService:
          _RecordingLocationAssistanceService(permissionGranted: true),
    );

    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -2400));
    await tester.pumpAndSettle();

    final footerText = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data?.startsWith('Conscia') ?? false) &&
          widget.data != 'Conscia Premium' &&
          widget.data != 'Shared Conscia',
    );
    final footerPadding = tester.widget<Padding>(
      find
          .ancestor(
            of: footerText,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Padding &&
                  widget.padding is EdgeInsets &&
                  (widget.padding as EdgeInsets).left == 20 &&
                  (widget.padding as EdgeInsets).top == 8 &&
                  (widget.padding as EdgeInsets).right == 20,
            ),
          )
          .first,
    );

    expect((footerPadding.padding as EdgeInsets).bottom, 32);
  });

  testWidgets('settings can toggle smart location suggestions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
      'location_suggestions_permission_denied': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);
    final userService = _RecordingUserService();

    final container = await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: userService,
    );

    await tester.pumpAndSettle();

    expect(find.text('Smart Nearby Suggestions'), findsOneWidget);
    expect(
      find.text('Uses approximate location on this device only'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Smart Nearby Suggestions'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(locationService.permissionRequests, 1);
    expect(
      container.read(locationAssistanceProvider).isEnabled,
      isTrue,
    );

    await tester.ensureVisible(find.text('Smart Nearby Suggestions'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(locationService.permissionRequests, 1);
    expect(
      container.read(locationAssistanceProvider).isEnabled,
      isFalse,
    );
  });

  testWidgets(
      'settings routes denied-forever location toggle attempts to system settings',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
      'location_suggestions_permission_denied': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final locationService = _RecordingLocationAssistanceService(
      permissionGranted: false,
      permissionStatus: LocationPermissionStatus.deniedForever,
    );

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: _RecordingUserService(),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Smart Nearby Suggestions'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(locationService.permissionRequests, 0);
    expect(locationService.openAppSettingsCalls, 1);
    expect(
      find.text(
        'Allow location access in your device settings to turn this on.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'settings routes location toggle attempts to device location settings when location is off',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'location_suggestions_enabled': false,
      'location_suggestions_prompted': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final locationService = _RecordingLocationAssistanceService(
      permissionGranted: false,
      locationServiceEnabled: false,
    );

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: _RecordingUserService(),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Smart Nearby Suggestions'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(locationService.permissionRequests, 0);
    expect(locationService.openLocationSettingsCalls, 1);
    expect(locationService.openAppSettingsCalls, 0);
    expect(
      find.text(
        'Turn on device location first, then try Smart Nearby Suggestions again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('settings removes the legacy biometric toggle', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService:
          _RecordingLocationAssistanceService(permissionGranted: true),
      overrides: [
        passkeyAvailabilityProvider.overrideWith((ref) async => false),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Biometric Sign-In'), findsNothing);
  });

  testWidgets('settings links sign-in methods to security', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService:
          _RecordingLocationAssistanceService(permissionGranted: true),
      overrides: [
        passkeyAvailabilityProvider.overrideWith((ref) async => true),
        currentSessionSupportsPasskeysProvider.overrideWith((ref) => true),
        passkeyServiceProvider.overrideWithValue(_RecordingPasskeyService()),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Password and passkey sign-in'), findsOneWidget);
    expect(find.text('Set Up Passkey'), findsNothing);
    expect(find.text('Biometric Sign-In'), findsNothing);
  });

  testWidgets('settings keeps passkey registration inside security',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final passkeyService = _RecordingPasskeyService();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService:
          _RecordingLocationAssistanceService(permissionGranted: true),
      overrides: [
        passkeyAvailabilityProvider.overrideWith((ref) async => true),
        currentSessionSupportsPasskeysProvider.overrideWith((ref) => true),
        passkeyServiceProvider.overrideWithValue(passkeyService),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Set Up Passkey'), findsNothing);
    expect(passkeyService.registerCount, 0);
    expect(prefs.getStringList(passkeyRegisteredEmailsPreferenceKey), isNull);
    expect(prefs.getBool(passkeyFirstSignInEnabledPreferenceKey), isNull);
  });

  testWidgets('settings can change region format', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);
    final userService = _RecordingUserService();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: userService,
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Locale & Number Format'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Locale & Number Format'));
    await tester.pumpAndSettle();

    expect(find.text('Region Format'), findsOneWidget);

    await tester.tap(find.text('European'));
    await tester.pumpAndSettle();

    expect(userService.lastLocale, 'de_DE');
  });

  testWidgets('region format uses checkmark selection in a settings list',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Locale & Number Format'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Locale & Number Format'));
    await tester.pumpAndSettle();

    expect(find.text('Region Format'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('Philippines / US'), findsNothing);
    expect(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Default'),
              matching: find.byType(InkWell),
            )
            .last,
        matching: find.byType(HugeIcon),
      ),
      findsOneWidget,
    );
    expect(find.byType(Radio<String>), findsNothing);
  });

  testWidgets(
      'settings locks default currency after transaction history exists',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);
    final userService = _RecordingUserService();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: userService,
      transactions: [
        Transaction(
          id: 'tx-1',
          amount: 42,
          currencyCode: 'USD',
          category: 'Dining',
          description: 'Cafe',
          type: 'expense',
          date: DateTime(2026, 5, 1),
        ),
      ],
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Default Currency'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(find.text('USD · locked after first transaction'), findsOneWidget);

    await tester.tap(find.text('Default Currency'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Currency'), findsNothing);
  });

  testWidgets('settings surfaces backend currency lock conflicts',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: _FailingCurrencyUserService(),
      isPremium: true,
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Default Currency'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Default Currency'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'AED'));
    await tester.pumpAndSettle();

    expect(
      find.text('Default currency is locked after your first transaction.'),
      findsOneWidget,
    );
  });

  testWidgets('settings can change ai personality intensity', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);
    final userService = _RecordingUserService();

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      userService: userService,
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('AI Personality'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI Personality'));
    await tester.pumpAndSettle();

    expect(find.text('Balanced'), findsWidgets);
    await tester.tap(find.text('Intense').last);
    await tester.pumpAndSettle();

    expect(userService.lastAiPersonalityIntensity, 'intense');
  });

  testWidgets('ai personality uses flat checkmark rows for mode selection',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('AI Personality'));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 120));
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI Personality'));
    await tester.pumpAndSettle();

    expect(find.byType(Radio<String>), findsNothing);
    expect(
      find.descendant(
        of: find
            .ancestor(
              of: find.text('Balanced').last,
              matching: find.byType(InkWell),
            )
            .last,
        matching: find.byType(HugeIcon),
      ),
      findsOneWidget,
    );
    expect(find.byType(Divider), findsWidgets);
  });

  testWidgets('shared conscia appears in the settings hero', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      familySpace: const FamilySpace(
        id: 'family-1',
        name: 'Santos Household',
        currencyCode: 'PHP',
        isReadOnly: false,
        role: 'Owner',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Shared Conscia'), findsOneWidget);
    expect(find.text('Santos Household'), findsOneWidget);
    expect(find.text('SHARED CONSCIA'), findsNothing);
  });

  testWidgets('settings hero keeps profile and shared conscia navigable', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      familySpace: const FamilySpace(
        id: 'family-1',
        name: 'Santos Household',
        currencyCode: 'PHP',
        isReadOnly: false,
        role: 'Owner',
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Shared Conscia'), findsOneWidget);
    expect(find.byKey(const ValueKey('settings-hero-profile-shortcut')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('settings-hero-family-shortcut')),
        findsOneWidget);
  });

  testWidgets(
      'settings uses editorial section headers with meaningful subtitles',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      overrides: [
        adminEntitlementAccessProvider.overrideWith((ref) async => true),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Money setup'), findsOneWidget);
    expect(
      find.text(
        'Shape how Conscia tracks categories, limits, and planning defaults.',
      ),
      findsOneWidget,
    );
    expect(find.text('Preferences'), findsOneWidget);
    expect(
      find.text('Tune guidance, formatting, and device-level behavior.'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('Conscia Premium'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Subscription'), findsOneWidget);
    expect(
      find.text('See your plan status and manage premium access.'),
      findsOneWidget,
    );
    expect(find.text('Operator'), findsOneWidget);
    expect(
      find.text(
        'Internal tools for account access, provisioning, and entitlements.',
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('Download my data'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Data & privacy'), findsOneWidget);
    expect(
      find.text('Control exports, account ownership, and permanent deletion.'),
      findsOneWidget,
    );

    expect(find.text('MONEY SETUP'), findsNothing);
    expect(find.text('PREFERENCES'), findsNothing);
    expect(find.text('SUBSCRIPTION'), findsNothing);
    expect(find.text('DATA & PRIVACY'), findsNothing);
  });

  testWidgets('settings hero shortcut subtitles truncate instead of wrapping', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      familySpace: const FamilySpace(
        id: 'family-1',
        name: 'The Incredibly Long Santos Household Workspace Name',
        currencyCode: 'PHP',
        isReadOnly: false,
        role: 'Owner',
      ),
    );

    await tester.pumpAndSettle();

    final subtitle = tester.widget<Text>(
      find.text('The Incredibly Long Santos Household Workspace Name'),
    );

    expect(subtitle.maxLines, 1);
    expect(subtitle.overflow, TextOverflow.ellipsis);
  });

  testWidgets('settings hero shortcuts stay in a two-column row', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      familySpace: const FamilySpace(
        id: 'family-1',
        name: 'Santos Household',
        currencyCode: 'PHP',
        isReadOnly: false,
        role: 'Owner',
      ),
    );

    await tester.pumpAndSettle();

    final profileTop = tester
        .getTopLeft(
            find.byKey(const ValueKey('settings-hero-profile-shortcut')))
        .dy;
    final familyTop = tester
        .getTopLeft(find.byKey(const ValueKey('settings-hero-family-shortcut')))
        .dy;

    expect(familyTop, closeTo(profileTop, 1));
  });

  testWidgets('preferences and planning rows are grouped in the intended order',
      (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Budgets'), 200);
    await tester.pumpAndSettle();

    expect(find.text('Money setup'), findsOneWidget);
    final planningTop = tester.getTopLeft(find.text('Money setup')).dy;
    final categoriesTop = tester.getTopLeft(find.text('Categories')).dy;
    final budgetsTop = tester.getTopLeft(find.text('Budgets')).dy;

    expect(categoriesTop, greaterThan(planningTop));
    expect(budgetsTop, lessThan(categoriesTop));
    expect(
      find.text('Create and tune monthly caps'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(find.text('AI Personality'), 200);
    await tester.pumpAndSettle();

    final aiTop = tester.getTopLeft(find.text('AI Personality')).dy;
    final smartLocationTop =
        tester.getTopLeft(find.text('Smart Nearby Suggestions')).dy;
    expect(aiTop, lessThan(smartLocationTop));
  });

  testWidgets('settings uses a bleeding hero with header sign out affordance',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    final hero = find.byKey(const ValueKey('settings-editorial-hero'));
    expect(hero, findsOneWidget);
    expect(tester.getTopLeft(hero).dx, 0);
    expect(tester.getTopLeft(hero).dy, 0);
    expect(tester.getTopLeft(find.text('Tune Conscia around you')).dy,
        lessThan(116));
    expect(find.text('SETTINGS HUB'), findsOneWidget);
    expect(find.text('Tune Conscia around you'), findsOneWidget);
    expect(find.textContaining('Personal workspace'), findsOneWidget);
    expect(find.byTooltip('Sign out'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Sign Out'), findsNothing);
  });

  testWidgets('settings hero shortcuts use menu item text scale',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    expect(find.byType(HeroShortcutCard), findsNWidgets(2));

    final profileTitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('settings-hero-profile-shortcut')),
        matching: find.text('Profile'),
      ),
    );
    final profileSubtitle = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('settings-hero-profile-shortcut')),
        matching: find.text('Personal workspace'),
      ),
    );
    final budgetsTitle = tester.widget<Text>(find.text('Budgets'));
    final budgetsSubtitle =
        tester.widget<Text>(find.text('Create and tune monthly caps'));

    expect(profileTitle.style?.fontSize, budgetsTitle.style?.fontSize);
    expect(profileSubtitle.style?.fontSize, budgetsSubtitle.style?.fontSize);
  });

  testWidgets('sign out confirmation uses a pull-up sheet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sign out'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Sign out?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sign out'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('settings shows data and privacy actions directly',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    expect(find.text('Data & About'), findsNothing);
    expect(find.text('Service Status'), findsNothing);
    await tester.scrollUntilVisible(find.text('Download my data'), 280);
    await tester.pumpAndSettle();

    expect(find.text('Data & privacy'), findsOneWidget);
    expect(find.text('Download my data'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);
  });

  testWidgets('settings hides admin entitlements for non-admin sessions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      overrides: [
        adminEntitlementAccessProvider.overrideWith((ref) async => false),
      ],
    );

    await tester.pumpAndSettle();

    expect(find.text('Admin entitlements'), findsNothing);
    expect(find.text('Operator'), findsNothing);
  });

  testWidgets('settings shows admin entitlements for admin sessions',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
      overrides: [
        adminEntitlementAccessProvider.overrideWith((ref) async => true),
      ],
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Admin entitlements'), 280);
    await tester.pumpAndSettle();

    expect(find.text('Operator'), findsOneWidget);
    expect(find.text('Admin entitlements'), findsOneWidget);
  });

  testWidgets('delete account confirmation uses a pull-up sheet',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Delete account'), 280);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Delete this account?'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Delete account'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
  });

  testWidgets('settings list groups are flat with separators, not cards',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final locationService =
        _RecordingLocationAssistanceService(permissionGranted: true);

    await _pumpSettingsScreen(
      tester,
      prefs: prefs,
      locationService: locationService,
    );

    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('AI Personality'), 200);
    await tester.pumpAndSettle();

    final groupMaterial = tester.widget<Material>(
      find.byKey(const ValueKey('settings-group-Preferences')),
    );
    expect(groupMaterial.color, Colors.transparent);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('settings-group-Preferences')),
        matching: find.byType(Divider),
      ),
      findsWidgets,
    );
  });
}
