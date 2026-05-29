import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../providers/conscience_journey_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../screens/assistant/pre_purchase_screen.dart';
import '../../screens/budgets/budgets_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/onboarding/about_you_screen.dart';
import '../../screens/onboarding/spending_profile_screen.dart';
import '../../screens/onboarding/suggested_budgets_screen.dart';
import '../../screens/onboarding/setup_screen.dart';
import '../../screens/onboarding/sign_in_screen.dart';
import '../../screens/onboarding/sign_up_screen.dart';
import '../../screens/onboarding/session_expired_screen.dart';
import '../../screens/onboarding/verify_email_screen.dart';
import '../../screens/onboarding/password_reset_screen.dart';
import '../../screens/receipts/receipt_review_screen.dart';
import '../../screens/receipts/receipt_scanner_screen.dart';
import '../../screens/settings/service_status_screen.dart';
import '../../screens/settings/category_management_screen.dart';
import '../../screens/settings/admin_entitlements_screen.dart';
import '../../screens/settings/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/family/family_invites_screen.dart';
import '../../screens/family/family_members_screen.dart';
import '../../screens/family/family_setup_screen.dart';
import '../../screens/family/family_space_settings_screen.dart';
import '../../screens/insights/category_detail_screen.dart';
import '../../screens/insights/category_list_screen.dart';
import '../../screens/insights/insights_screen.dart';
import '../../screens/journey/conscience_journey_screen.dart';
import '../../screens/journey/level_up_screen.dart';
import '../../screens/insights/merchant_detail_screen.dart';
import '../../screens/insights/merchant_list_screen.dart';
import '../../screens/transactions/transaction_detail_screen.dart';
import '../../screens/transactions/transaction_form_screen.dart';
import '../../screens/transactions/transaction_list_screen.dart';
import '../../widgets/main_shell.dart';

abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const signIn = '/onboarding/sign-in';
  static const signUp = '/onboarding/sign-up';
  static const passwordReset = '/onboarding/password-reset';
  static const verifyEmail = '/onboarding/verify-email';
  static const sessionExpired = '/session-expired';
  static const setup = '/onboarding/setup';
  static const spendingProfile = '/onboarding/profile';
  static const suggestedBudgets = '/onboarding/budgets';
  static const aboutYou = '/onboarding/about';

  static const home = '/';
  static const transactions = '/transactions';
  static const addTransaction = '/transactions/add';
  static String transactionDetail(String id, {bool autoReflect = false}) =>
      autoReflect ? '/transactions/$id?autoReflect=1' : '/transactions/$id';
  static String editTransaction(String id) => '/transactions/$id/edit';

  static const assistant = '/assistant';
  static const insights = '/insights';
  static const journey = '/journey';
  static const levelUp = '/journey/level-up';

  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const settingsAdminEntitlements = '/settings/admin-entitlements';
  static const categories = '/settings/categories';
  static const serviceStatus = '/settings/status';
  static const budgets = '/settings/budgets';
  static const familySpace = '/settings/family-space';
  static const familySetup = '/settings/family-space/setup';
  static const familyInvites = '/settings/family-space/invites';
  static const familyMembers = '/settings/family-space/members';

  static const scan = '/scan';
  static String reviewReceipt(String id) => '/receipts/$id/review';
}

const _hasOnboardedKey = 'has_completed_onboarding';
const _lastEmailKey = 'last_login_email';

Future<bool> hasCompletedOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_hasOnboardedKey) ?? false;
}

Future<void> markOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_hasOnboardedKey, true);
}

Future<void> saveLastEmail(String email) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_lastEmailKey, email);
}

Future<String?> getLastEmail() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_lastEmailKey);
}

String familyInviteRoute({String? inviteId}) {
  if (inviteId == null || inviteId.isEmpty) {
    return AppRoutes.familyInvites;
  }

  return Uri(
    path: AppRoutes.familyInvites,
    queryParameters: {
      'inviteId': inviteId,
    },
  ).toString();
}

String? resolveIncomingAppLink(Uri uri) {
  if (uri.scheme == 'conscia' && uri.host == 'invite') {
    return familyInviteRoute(inviteId: uri.queryParameters['inviteId']);
  }

  if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      (uri.host == 'getconscia.com' || uri.host == 'www.getconscia.com')) {
    if (uri.path == '/invite' || uri.path == '/open/family-invite') {
      return familyInviteRoute(inviteId: uri.queryParameters['inviteId']);
    }

    if (uri.path == AppRoutes.familyInvites) {
      return uri
          .replace(
            scheme: '',
            host: '',
            port: 0,
          )
          .toString();
    }
  }

  return null;
}

Map<String, String?>? _routeStringExtras(Object? extra) {
  if (extra is! Map) return null;

  return extra.map(
    (key, value) => MapEntry(
      key.toString(),
      value?.toString(),
    ),
  );
}

class _RouterRefreshListenable extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final hasOnboardedProvider =
    FutureProvider<bool>((ref) => hasCompletedOnboarding());

@visibleForTesting
String determineInitialLocation({Uri? baseUri, bool? isWebOverride}) {
  final isWeb = isWebOverride ?? kIsWeb;
  if (!isWeb) {
    return AppRoutes.home;
  }

  final uri = baseUri ?? Uri.base;
  final path = uri.path.isEmpty ? AppRoutes.home : uri.path;
  final query = uri.hasQuery ? '?${uri.query}' : '';
  final fragment = uri.hasFragment ? '#${uri.fragment}' : '';

  return '$path$query$fragment';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _RouterRefreshListenable();
  ref.onDispose(listenable.dispose);
  ref.listen<AuthState>(authProvider, (_, __) => listenable.refresh());
  ref.listen<AsyncValue<bool>>(
      hasOnboardedProvider, (_, __) => listenable.refresh());
  ref.listen<AsyncValue<UserProfile>>(
      currentUserProvider, (_, __) => listenable.refresh());

  return GoRouter(
    initialLocation: determineInitialLocation(),
    debugLogDiagnostics: kDebugMode,
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isSessionExpired = authState.isSessionExpired;
      final localHasOnboarded =
          ref.read(hasOnboardedProvider).valueOrNull ?? false;
      final currentUserAsync =
          isAuthenticated ? ref.read(currentUserProvider) : null;
      final userProfile = currentUserAsync?.valueOrNull;
      final hasOnboarded =
          userProfile?.hasCompletedOnboarding ?? localHasOnboarded;
      final isOnboarding = state.uri.path.startsWith('/onboarding');
      final isOnboardingLanding = state.uri.path == AppRoutes.onboarding;
      final isVerifyEmailRoute = state.uri.path == AppRoutes.verifyEmail;
      final isSignInRoute = state.uri.path == AppRoutes.signIn;
      final isSessionExpiredRoute = state.uri.path == AppRoutes.sessionExpired;
      final isHealthCheck = state.uri.path.startsWith('/health');
      final redirectTarget = state.uri.queryParameters['redirect'];

      if (isHealthCheck) return null;

      if (authState.isRestoringSession) {
        return null;
      }

      if (isSessionExpired) {
        return isSessionExpiredRoute ? null : AppRoutes.sessionExpired;
      }

      if (authState.status == AuthStatus.pendingConfirmation) {
        return isVerifyEmailRoute ? null : AppRoutes.verifyEmail;
      }

      if (!isAuthenticated && (!isOnboarding || isOnboardingLanding)) {
        if (isSignInRoute) {
          return null;
        }

        if (authState.wasExplicitLogout) {
          return AppRoutes.signIn;
        }

        return Uri(
          path: AppRoutes.signIn,
          queryParameters: {
            'redirect': state.uri.toString(),
          },
        ).toString();
      }

      if (isAuthenticated && (currentUserAsync?.isLoading ?? false)) {
        return null;
      }

      if (isAuthenticated && isOnboarding) {
        const allowedOnboardingRoutes = {
          AppRoutes.setup,
          AppRoutes.spendingProfile,
          AppRoutes.suggestedBudgets,
          AppRoutes.aboutYou,
        };

        if (hasOnboarded) {
          if (isSignInRoute &&
              redirectTarget != null &&
              redirectTarget.isNotEmpty) {
            return redirectTarget;
          }

          return AppRoutes.home;
        }
        if (!allowedOnboardingRoutes.contains(state.uri.path)) {
          return AppRoutes.setup;
        }
      }

      if (isAuthenticated && !hasOnboarded && !isOnboarding) {
        return AppRoutes.setup;
      }

      return null;
    },
    routes: [
      // ── Onboarding ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        redirect: (context, state) =>
            state.uri.path == AppRoutes.onboarding ? AppRoutes.signIn : null,
        routes: [
          GoRoute(
            path: 'sign-in',
            builder: (context, state) => const SignInScreen(),
          ),
          GoRoute(
            path: 'sign-up',
            builder: (context, state) => const SignUpScreen(),
          ),
          GoRoute(
            path: 'password-reset',
            builder: (context, state) => const PasswordResetScreen(),
          ),
          GoRoute(
            path: 'verify-email',
            builder: (context, state) => const VerifyEmailScreen(),
          ),
          GoRoute(
            path: 'setup',
            builder: (context, state) => const SetupScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (context, state) {
              final extra = _routeStringExtras(state.extra);
              return SpendingProfileScreen(
                initialCurrencyCode: extra?['currencyCode'],
                initialLocale: extra?['locale'],
              );
            },
          ),
          GoRoute(
            path: 'budgets',
            builder: (context, state) {
              final extra = _routeStringExtras(state.extra);
              return SuggestedBudgetsScreen(
                spendingPersonality:
                    extra?['spendingPersonality'] ?? 'balanced',
                incomeRange: extra?['incomeRange'] ?? 'mid',
              );
            },
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutYouScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.sessionExpired,
        builder: (context, state) => const SessionExpiredScreen(),
      ),

      // ── Main shell with bottom nav ─────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // ── Full-screen routes ─────────────────────────────────────────
      GoRoute(
        path: AppRoutes.assistant,
        builder: (context, state) => const PrePurchaseScreen(),
      ),
      GoRoute(
        path: '/transactions/add',
        builder: (context, state) {
          final extra = _routeStringExtras(state.extra);
          return TransactionFormScreen(
            initialAmount: extra?['amount'],
            initialCurrencyCode: extra?['currencyCode'],
            initialCategory: extra?['category'],
            initialCounterparty: extra?['counterparty'],
            initialScope: extra?['scope'],
          );
        },
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          final autoReflect = state.uri.queryParameters['autoReflect'] == '1';
          return TransactionDetailScreen(
            transactionId: id,
            autoReflect: autoReflect,
          );
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return TransactionFormScreen(transactionId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsAdminEntitlements,
        builder: (context, state) => const AdminEntitlementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.categories,
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/settings/status',
        builder: (context, state) => const ServiceStatusScreen(),
      ),
      GoRoute(
        path: '/settings/budgets',
        builder: (context, state) => const BudgetsScreen(),
      ),
      GoRoute(
        path: AppRoutes.familySpace,
        builder: (context, state) => const FamilySpaceSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.familySetup,
        builder: (context, state) => const FamilySetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.familyInvites,
        builder: (context, state) => const FamilyInvitesScreen(),
      ),
      GoRoute(
        path: AppRoutes.familyMembers,
        builder: (context, state) => const FamilyMembersScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ReceiptScannerScreen(),
      ),
      GoRoute(
        path: '/receipts/:id/review',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReceiptReviewScreen(receiptId: id);
        },
      ),
      GoRoute(
        path: '/insights',
        builder: (context, state) => const InsightsScreen(),
      ),
      GoRoute(
        path: AppRoutes.levelUp,
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final summary = ref.watch(conscienceJourneyProvider).valueOrNull;
              if (summary == null) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return LevelUpScreen(summary: summary);
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.journey,
        builder: (context, state) => const ConscienceJourneyScreen(),
      ),
      GoRoute(
        path: '/insights/merchants',
        builder: (context, state) => const MerchantListScreen(),
      ),
      GoRoute(
        path: '/insights/merchants/:merchant',
        builder: (context, state) =>
            MerchantDetailScreen(merchant: state.pathParameters['merchant']!),
      ),
      GoRoute(
        path: '/insights/categories',
        builder: (context, state) => const CategoryListScreen(),
      ),
      GoRoute(
        path: '/insights/categories/:category',
        builder: (context, state) =>
            CategoryDetailScreen(category: state.pathParameters['category']!),
      ),
    ],
  );
});
