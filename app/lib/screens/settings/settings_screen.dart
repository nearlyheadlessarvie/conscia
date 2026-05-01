import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/currency_picker_sheet.dart';
import 'widgets/subscription_card.dart';
import 'widgets/subscription_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final userAsync = ref.watch(currentUserProvider);
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Section: Profile
          _sectionHeader(textTheme, 'Profile'),
          userAsync.when(
            data: (user) => ListTile(
              leading: CircleAvatar(
                child: Text(
                  user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                ),
              ),
              title: Text(user.email),
              subtitle: Text(
                'Member since ${_formatDate(user.createdAt)}',
              ),
            ),
            loading: () => const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Loading...'),
            ),
            error: (_, __) => const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Unable to load profile'),
            ),
          ),
          const Divider(),

          // Section: Preferences
          _sectionHeader(textTheme, 'Preferences'),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Default Currency'),
            subtitle: Text(
              ref.watch(userPreferencesProvider).currency,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.format_list_numbered),
            title: const Text('Number Format'),
            subtitle: const Text('1,234.56'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),

          // Section: Budgets
          _sectionHeader(textTheme, 'Budgets'),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('Manage Budgets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/settings/budgets'),
          ),
          const Divider(),

          // Section: Subscription
          _sectionHeader(textTheme, 'Subscription'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: subAsync.when(
              data: (status) => SubscriptionCard(
                status: status,
                onUpgrade: () => SubscriptionSheet.show(context),
                onManage: () {},
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Unable to load subscription'),
            ),
          ),
          const Divider(),

          // Section: About
          _sectionHeader(textTheme, 'About'),
          _ServiceStatusTile(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Sign Out',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmSignOut(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('Version 1.0.0 (build 1)'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(TextTheme textTheme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(userPreferencesProvider).currency;
    CurrencyPickerSheet.show(
      context,
      selectedCode: current,
      onSelected: (code) {
        // TODO: call userService.updateProfile(currencyCode: code)
      },
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _ServiceStatusTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthStatusProvider);
    final colors = Theme.of(context).appColors;

    Color dotColor;
    String subtitle;
    if (state.isLoading && state.status == null) {
      dotColor = Theme.of(context).colorScheme.outline;
      subtitle = 'Checking...';
    } else if (state.error != null && state.status == null) {
      dotColor = colors.expense;
      subtitle = 'Unavailable';
    } else {
      subtitle = state.overallLabel;
      switch (state.status?.status) {
        case 'Healthy':
          dotColor = colors.income;
        case 'Degraded':
          dotColor = colors.budgetCaution;
        default:
          dotColor = colors.expense;
      }
    }

    return ListTile(
      leading: const Icon(Icons.monitor_heart_outlined),
      title: const Text('Service Status'),
      subtitle: Text(subtitle),
      trailing: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
      onTap: () => context.push(AppRoutes.serviceStatus),
    );
  }
}
