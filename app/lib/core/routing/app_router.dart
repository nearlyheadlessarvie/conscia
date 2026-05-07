import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/user_service.dart';
import '../../screens/assistant/pre_purchase_screen.dart';
import '../../screens/budgets/budgets_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/onboarding/about_you_screen.dart';
import '../../screens/onboarding/spending_profile_screen.dart';
import '../../screens/onboarding/suggested_budgets_screen.dart';
import '../../screens/onboarding/setup_screen.dart';
import '../../screens/onboarding/sign_in_screen.dart';
import '../../screens/onboarding/sign_up_screen.dart';
import '../../screens/receipts/receipt_review_screen.dart';
import '../../screens/receipts/receipt_scanner_screen.dart';
import '../../screens/settings/service_status_screen.dart';
import '../../screens/settings/profile_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/insights/category_detail_screen.dart';
import '../../screens/insights/category_list_screen.dart';
import '../../screens/insights/insights_screen.dart';
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
  static const setup = '/onboarding/setup';
  static const spendingProfile = '/onboarding/profile';
  static const suggestedBudgets = '/onboarding/budgets';
  static const aboutYou = '/onboarding/about';

  static const home = '/';
  static const transactions = '/transactions';
  static const addTransaction = '/transactions/add';
  static String transactionDetail(String id) => '/transactions/$id';
  static String editTransaction(String id) => '/transactions/$id/edit';

  static const assistant = '/assistant';

  static const settings = '/settings';
  static const settingsProfile = '/settings/profile';
  static const serviceStatus = '/settings/status';
  static const budgets = '/settings/budgets';

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

final hasOnboardedProvider = FutureProvider<bool>((ref) => hasCompletedOnboarding());

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _RouterRefreshListenable();
  ref.onDispose(listenable.dispose);
  ref.listen<AuthState>(authProvider, (_, __) => listenable.refresh());
  ref.listen<AsyncValue<bool>>(hasOnboardedProvider, (_, __) => listenable.refresh());
  ref.listen<AsyncValue<UserProfile>>(currentUserProvider, (_, __) => listenable.refresh());

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final localHasOnboarded =
          ref.read(hasOnboardedProvider).valueOrNull ?? false;
      final currentUserAsync =
          isAuthenticated ? ref.read(currentUserProvider) : null;
      final userProfile = currentUserAsync?.valueOrNull;
      final hasOnboarded =
          userProfile?.hasCompletedOnboarding ?? localHasOnboarded;
      final isOnboarding = state.uri.path.startsWith('/onboarding');
      final isHealthCheck = state.uri.path.startsWith('/health');

      if (isHealthCheck) return null;

      if (!isAuthenticated && !isOnboarding) {
        return hasOnboarded ? AppRoutes.signIn : AppRoutes.onboarding;
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

        if (hasOnboarded) return AppRoutes.home;
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
        builder: (context, state) => const OnboardingScreen(),
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
                spendingPersonality: extra?['spendingPersonality'] ?? 'balanced',
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
            path: AppRoutes.assistant,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PrePurchaseScreen(),
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
        path: '/transactions/add',
        builder: (context, state) {
          final extra = _routeStringExtras(state.extra);
          return TransactionFormScreen(
            initialAmount: extra?['amount'],
            initialCurrencyCode: extra?['currencyCode'],
            initialCategory: extra?['category'],
            initialCounterparty: extra?['counterparty'],
          );
        },
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TransactionDetailScreen(transactionId: id);
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
        path: '/settings/status',
        builder: (context, state) => const ServiceStatusScreen(),
      ),
      GoRoute(
        path: '/settings/budgets',
        builder: (context, state) => const BudgetsScreen(),
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
