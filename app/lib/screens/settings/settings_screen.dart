import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/network/dio_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_provider.dart';
import '../../providers/location_assistance_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/currency_picker_sheet.dart';
import '../../widgets/locale_picker_sheet.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/subscription_card.dart';
import 'widgets/subscription_sheet.dart';

const _biometricEnabledKey = 'biometric_enabled';
const _aiIntensityOptions = <({
  String value,
  String label,
  String description,
})>[
  (
    value: 'mild',
    label: 'Mild',
    description: 'Softer tone with gentler push-and-pull.',
  ),
  (
    value: 'balanced',
    label: 'Balanced',
    description: 'Default mix of warmth, clarity, and directness.',
  ),
  (
    value: 'intense',
    label: 'Intense',
    description: 'Sharper contrast between impulse, reason, and reflection.',
  ),
];

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricSupported = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_appLifecycleObserver);
    _loadBiometricState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(subscriptionProvider);
    });
  }

  late final WidgetsBindingObserver _appLifecycleObserver =
      _SettingsLifecycleObserver(
    onResume: () {
      if (!mounted) return;
      ref.invalidate(subscriptionProvider);
    },
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_appLifecycleObserver);
    super.dispose();
  }

  Future<void> _loadBiometricState() async {
    final auth = LocalAuthentication();
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _biometricSupported = canCheck && isSupported;
          _biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      final auth = LocalAuthentication();
      final authenticated = await auth.authenticate(
        localizedReason: 'Verify your identity to enable biometric sign-in',
        options:
            const AuthenticationOptions(stickyAuth: true, biometricOnly: true),
      );
      if (!authenticated) return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final userAsync = ref.watch(currentUserProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final locationAssistance = ref.watch(locationAssistanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Profile ──────────────────────────────────────────
          _sectionHeader(textTheme, 'Profile'),
          userAsync.when(
            data: (user) => ListTile(
              leading: CircleAvatar(
                child: Text(
                  user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                ),
              ),
              title: Text(user.email),
              subtitle: Text('Member since ${_formatDate(user.createdAt)}'),
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
          ListTile(
            leading: Icon(AppIcons.person),
            title: const Text('My Profile'),
            subtitle: const Text('Spending style, income, household'),
            trailing: Icon(AppIcons.chevronRight),
            onTap: () => context.push(AppRoutes.settingsProfile),
          ),
          const Divider(),

          // ── Preferences ──────────────────────────────────────
          _sectionHeader(textTheme, 'Preferences'),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Default Currency'),
            subtitle: Text(ref.watch(userPreferencesProvider).currency),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Region / Number Format'),
            subtitle: Text(ref.watch(userPreferencesProvider).locale),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLocalePicker(context, ref),
          ),
          if (_biometricSupported)
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Sign-In'),
              subtitle: const Text('Use fingerprint or face to sign in'),
              value: _biometricEnabled,
              onChanged: _toggleBiometric,
            ),
          SwitchListTile(
            secondary: const Icon(Icons.location_searching_outlined),
            title: const Text('Smart location suggestions'),
            subtitle: Text(
              [
                'Currently ${locationAssistance.isEnabled ? 'on' : 'off'} for nearby merchant and category suggestions.',
                if (!locationAssistance.isEnabled &&
                    locationAssistance.permissionDenied)
                  'System location permission may also need to be enabled.',
              ].join(' '),
            ),
            value: locationAssistance.isEnabled,
            onChanged: (value) async {
              final notifier = ref.read(locationAssistanceProvider.notifier);
              if (value) {
                await notifier.enableFromSettings();
              } else {
                await notifier.disableFromSettings();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('AI Personality Intensity'),
            subtitle: Text(
              userAsync.maybeWhen(
                data: (user) =>
                    _labelForAiIntensity(user.aiPersonalityIntensity),
                orElse: () => 'Balanced',
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: userAsync.maybeWhen(
              data: (_) => () => _showAiIntensityPicker(context, ref),
              orElse: () => null,
            ),
          ),
          const Divider(),

          // ── Budgets ──────────────────────────────────────────
          _sectionHeader(textTheme, 'Budgets'),
          ListTile(
            leading: const Icon(Icons.pie_chart_outline),
            title: const Text('Manage Budgets'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.budgets),
          ),
          const Divider(),

          // ── Subscription ─────────────────────────────────────
          _sectionHeader(textTheme, 'Subscription'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: subAsync.when(
              data: (status) => SubscriptionCard(
                status: status,
                onUpgrade: () => SubscriptionSheet.show(context),
                onManage: () => SubscriptionSheet.show(context),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SkeletonCard(),
              ),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Unable to load subscription'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(subscriptionProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          if (ApiConstants.useMockAuth) _DevUpgradeTile(),
          const Divider(),

          // ── Data & Privacy ───────────────────────────────────
          _sectionHeader(textTheme, 'Data & Privacy'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export My Data'),
            subtitle: const Text('Download all your data as JSON'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text('Delete Account',
                style: TextStyle(color: theme.colorScheme.error)),
            subtitle: const Text('Permanently remove all your data'),
            onTap: () => _confirmDeleteAccount(context, ref),
          ),
          const Divider(),

          // ── About ────────────────────────────────────────────
          _sectionHeader(textTheme, 'About'),
          _ServiceStatusTile(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('App Version'),
            subtitle: Text('Version 1.0.0 (build 1)'),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.logout, color: theme.colorScheme.error),
                label: Text('Sign Out',
                    style: TextStyle(color: theme.colorScheme.error)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: theme.colorScheme.error.withValues(alpha: 0.5)),
                ),
                onPressed: () => _confirmSignOut(context, ref),
              ),
            ),
          ),
          const SizedBox(height: 32),
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
    final isPremium =
        ref.read(subscriptionProvider).valueOrNull?.isPremium ?? false;
    CurrencyPickerSheet.show(
      context,
      selectedCode: current,
      isPremium: isPremium,
      onSelected: (code) async {
        try {
          await ref
              .read(userServiceProvider)
              .updateProfile(preferredCurrency: code);
          ref.invalidate(currentUserProvider);
        } catch (_) {}
      },
    );
  }

  void _showLocalePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(userPreferencesProvider).locale;
    LocalePickerSheet.show(
      context,
      selectedLocale: current,
      onSelected: (locale) async {
        try {
          await ref.read(userServiceProvider).updateProfile(locale: locale);
          ref.invalidate(currentUserProvider);
        } catch (_) {}
      },
    );
  }

  void _showAiIntensityPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(currentUserProvider).valueOrNull;
    if (current == null) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('AI Personality Intensity'),
                subtitle: Text(
                  'Applies across Pre-Purchase, Reflection, and future AI guidance.',
                ),
              ),
              for (final option in _aiIntensityOptions)
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  title: Text(option.label),
                  subtitle: Text(option.description),
                  trailing: option.value == current.aiPersonalityIntensity
                      ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                      : const Icon(Icons.circle_outlined),
                  selected: option.value == current.aiPersonalityIntensity,
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    try {
                      await ref.read(userServiceProvider).updateProfile(
                            aiPersonalityIntensity: option.value,
                          );
                      ref.invalidate(currentUserProvider);
                    } catch (_) {}
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final shareOrigin = _sharePositionOrigin(context);
    try {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(content: Text('Preparing your data export...')),
      );
      final dio = ref.read(dioProvider);
      final response = await dio.get(ApiConstants.profileExport);

      final exportJson = const JsonEncoder.withIndent('  ').convert(
        _normalizeExportPayload(response.data),
      );
      final timestamp =
          DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
      final filename = 'conscia-data-export-$timestamp.json';

      if (!context.mounted) return;

      try {
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                utf8.encode(exportJson),
                mimeType: 'application/json',
              ),
            ],
            fileNameOverrides: [filename],
            subject: 'Conscia data export',
            text: 'Your Conscia data export is ready.',
            sharePositionOrigin: shareOrigin,
          ),
        );

        if (!context.mounted) return;

        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              switch (result.status) {
                ShareResultStatus.success =>
                  'Export ready. Save or share the JSON file from the sheet.',
                ShareResultStatus.dismissed =>
                  'Export prepared. You can try again whenever you are ready.',
                ShareResultStatus.unavailable =>
                  'Sharing is unavailable here. Showing the raw JSON export instead.',
              },
            ),
          ),
        );

        if (result.status == ShareResultStatus.unavailable) {
          if (!mounted) return;
          await _showExportFallbackDialog(
            exportJson: exportJson,
            filename: filename,
          );
        }
      } on MissingPluginException {
        if (!mounted) return;
        await _showExportFallbackDialog(
          exportJson: exportJson,
          filename: filename,
          pluginUnavailable: true,
        );
      }
    } catch (e) {
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Object? _normalizeExportPayload(Object? data) {
    if (data is Map) {
      return Map<String, Object?>.fromEntries(
        data.entries.map(
          (entry) => MapEntry(
              entry.key.toString(), _normalizeExportPayload(entry.value)),
        ),
      );
    }

    if (data is List) {
      return data.map(_normalizeExportPayload).toList(growable: false);
    }

    return data;
  }

  Rect? _sharePositionOrigin(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;

    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _showExportFallbackDialog({
    required String exportJson,
    required String filename,
    bool pluginUnavailable = false,
  }) async {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Data Export Ready'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pluginUnavailable
                    ? 'Sharing is not available in this app build yet. You can still copy the JSON export below.'
                    : 'Sharing is unavailable on this device. You can still copy the JSON export below.',
              ),
              const SizedBox(height: 12),
              Text(
                filename,
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(exportJson),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: exportJson));
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              messenger.clearSnackBars();
              messenger.showSnackBar(
                const SnackBar(
                    content: Text('Export JSON copied to clipboard.')),
              );
            },
            child: const Text('Copy JSON'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data '
          '(transactions, budgets, AI interactions, receipts). '
          'This action cannot be undone.\n\n'
          'We recommend exporting your data first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final dio = ref.read(dioProvider);
                await dio.delete('users/me');
                if (!context.mounted) return;
                ref.read(authProvider.notifier).logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted.')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete account: $e')),
                );
              }
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _labelForAiIntensity(String intensity) {
    for (final option in _aiIntensityOptions) {
      if (option.value == intensity) return option.label;
    }
    return 'Balanced';
  }
}

class _DevUpgradeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium =
        ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;

    if (isPremium) {
      return const ListTile(
        leading: Icon(Icons.check_circle, color: Colors.green),
        title: Text('[DEV] Already Premium'),
      );
    }

    return ListTile(
      leading: const Icon(Icons.rocket_launch, color: Colors.orange),
      title: const Text('[DEV] Simulate Upgrade'),
      subtitle: const Text('Calls verify endpoint with trust-client fallback'),
      onTap: () => _upgrade(context, ref),
    );
  }

  Future<void> _upgrade(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '${ApiConstants.verifyReceipt}/ios',
        data: {'token': 'dev-simulate-upgrade'},
      );
      ref.invalidate(subscriptionProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Upgraded to Premium!')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }
}

class _ServiceStatusTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(healthStatusProvider);
    final colors = Theme.of(context).appColors;

    final Color dotColor;
    final String subtitle;
    if (state.isLoading && state.status == null) {
      dotColor = Theme.of(context).colorScheme.outline;
      subtitle = 'Checking...';
    } else if (state.error != null && state.status == null) {
      dotColor = colors.expense;
      subtitle = 'Unavailable';
    } else {
      subtitle = state.overallLabel;
      dotColor = switch (state.status?.status) {
        'Healthy' => colors.income,
        'Degraded' => colors.budgetCaution,
        _ => colors.expense,
      };
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

class _SettingsLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;

  _SettingsLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
