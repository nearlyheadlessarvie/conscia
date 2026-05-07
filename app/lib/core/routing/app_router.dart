import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
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

class _AuthNotifierListenable extends ChangeNotifier {
  _AuthNotifierListenable(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final hasOnboardedProvider = FutureProvider<bool>((ref) => hasCompletedOnboarding());

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthNotifierListenable(ref);
  final hasOnboarded = ref.watch(hasOnboardedProvider).valueOrNull ?? false;

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: listenable,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final isOnboarding = state.uri.path.startsWith('/onboarding');
      final isHealthCheck = state.uri.path.startsWith('/health');

      if (isHealthCheck) return null;

      if (!isAuthenticated && !isOnboarding) {
        return hasOnboarded ? AppRoutes.signIn : AppRoutes.onboarding;
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
            builder: (context, state) => const SpendingProfileScreen(),
          ),
          GoRoute(
            path: 'budgets',
            builder: (context, state) {
              final extra = state.extra as Map<String, String?>?;
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
        builder: (context, state) => const TransactionFormScreen(),
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
    ],
  );
});
