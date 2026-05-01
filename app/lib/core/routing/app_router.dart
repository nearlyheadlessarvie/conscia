import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/onboarding/setup_screen.dart';
import '../../screens/onboarding/sign_in_screen.dart';
import '../../screens/onboarding/sign_up_screen.dart';
import '../../screens/settings/service_status_screen.dart';
import '../../screens/transactions/transaction_list_screen.dart';
import '../../widgets/main_shell.dart';

abstract class AppRoutes {
  static const onboarding = '/onboarding';
  static const signIn = '/onboarding/sign-in';
  static const signUp = '/onboarding/sign-up';
  static const setup = '/onboarding/setup';

  static const home = '/';
  static const transactions = '/transactions';
  static const addTransaction = '/transactions/add';
  static String transactionDetail(String id) => '/transactions/$id';
  static String editTransaction(String id) => '/transactions/$id/edit';

  static const assistant = '/assistant';

  static const settings = '/settings';
  static const serviceStatus = '/settings/status';
  static const budgets = '/settings/budgets';

  static const scan = '/scan';
  static String reviewReceipt(String id) => '/receipts/$id/review';
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = ref.read(authProvider.notifier);

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(notifier.stream),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isOnboarding = state.uri.path.startsWith('/onboarding');
      final isHealthCheck = state.uri.path.startsWith('/health');

      if (isHealthCheck) return null;

      if (!isAuthenticated && !isOnboarding) {
        return AppRoutes.onboarding;
      }

      if (isAuthenticated && isOnboarding) {
        return AppRoutes.home;
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
              child: _Placeholder('Assistant'),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: _Placeholder('Settings'),
            ),
          ),
        ],
      ),

      // ── Full-screen routes ─────────────────────────────────────────
      GoRoute(
        path: '/transactions/add',
        builder: (context, state) => const _Placeholder('Add Transaction'),
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _Placeholder('Transaction $id');
        },
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return _Placeholder('Edit Transaction $id');
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings/status',
        builder: (context, state) => const ServiceStatusScreen(),
      ),
      GoRoute(
        path: '/settings/budgets',
        builder: (context, state) => const _Placeholder('Budgets'),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const _Placeholder('Scan Receipt'),
      ),
      GoRoute(
        path: '/receipts/:id/review',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return _Placeholder('Review Receipt $id');
        },
      ),
    ],
  );
}

/// Temporary placeholder for screens not yet built.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
