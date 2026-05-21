import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/network/dio_client.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/family_space.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_space_provider.dart';
import '../../providers/location_assistance_provider.dart';
import '../../providers/passkey_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_provider.dart';
import '../../services/passkey_service.dart';
import '../../services/user_service.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/conscia_bottom_sheet.dart';
import '../../widgets/conscia_confirm_sheet.dart';
import '../../widgets/currency_picker_sheet.dart';
import '../../widgets/editorial_hero_chip.dart';
import '../../widgets/locale_picker_sheet.dart';
import '../../widgets/single_select_list.dart';
import 'widgets/subscription_sheet.dart';

final _packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

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

const _regionFormatLabels = <String, String>{
  'en_US': 'Default',
  'de_DE': 'European',
  'fr_FR': 'French / Swiss',
  'en_IN': 'Indian',
};

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _appBarScrollProgress = ValueNotifier<double>(0);
  final _scrollController = ScrollController();
  bool _isRegisteringPasskey = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncAppBarProgressFromController);
    WidgetsBinding.instance.addObserver(_appLifecycleObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAppBarProgressFromController();
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
    _scrollController.removeListener(_syncAppBarProgressFromController);
    _scrollController.dispose();
    _appBarScrollProgress.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _syncAppBarProgressFromPixels(notification.metrics.pixels);
    }
    return false;
  }

  void _syncAppBarProgressFromController() {
    if (!_scrollController.hasClients) return;
    _syncAppBarProgressFromPixels(_scrollController.offset);
  }

  void _syncAppBarProgressFromPixels(double pixels) {
    final nextProgress = (pixels / 10).clamp(0.0, 1.0);
    if (_appBarScrollProgress.value != nextProgress) {
      _appBarScrollProgress.value = nextProgress;
    }
  }

  Future<void> _registerPasskey(BuildContext context) async {
    if (_isRegisteringPasskey) return;

    setState(() => _isRegisteringPasskey = true);
    try {
      await ref.read(passkeyServiceProvider).registerCurrentUserPasskey();
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Passkey ready on this device.')),
        );
    } catch (error) {
      if (!mounted || !context.mounted) return;
      if (!isPasskeyCancellation(error)) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(friendlyPasskeyErrorMessage(error))),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegisteringPasskey = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final familySpaceAsync = ref.watch(familySpaceProvider);
    final subAsync = ref.watch(subscriptionProvider);
    final locationAssistance = ref.watch(locationAssistanceProvider);
    final passkeysAvailable =
        ref.watch(passkeyAvailabilityProvider).valueOrNull ?? false;
    final sessionSupportsPasskeys =
        ref.watch(currentSessionSupportsPasskeysProvider);
    final userPreferences = ref.watch(userPreferencesProvider);
    final hasTransactionHistory =
        ref.watch(transactionListProvider).transactions.isNotEmpty;

    return ConsciaAppBarScrollScope(
      scrollProgress: _appBarScrollProgress,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: ConsciaAppBar(
          title: const Text('Settings'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: Icon(Icons.logout_rounded, color: theme.appColors.deepNavy),
              onPressed: () => _confirmSignOut(context, ref),
            ),
          ],
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.appColors.pageTop, theme.appColors.pageBottom],
              ),
            ),
            child: CustomScrollView(
              key: const PageStorageKey('settings-shell-scroll'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: userAsync.when(
                    data: (user) => _SettingsEditorialHero(
                      user: user,
                      familySpace: familySpaceAsync.valueOrNull,
                      currencyCode: userPreferences.currency,
                      locale: userPreferences.locale,
                      onProfileTap: () =>
                          context.push(AppRoutes.settingsProfile),
                      onFamilyTap: () => context.push(AppRoutes.familySpace),
                    ),
                    loading: () => const _SettingsEditorialHeroSkeleton(),
                    error: (_, __) => const _SettingsEditorialHeroFallback(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  sliver: SliverList.list(
                    children: [
                      _SettingsGroup(
                        title: 'Money Setup',
                        children: [
                          _SettingsActionRow(
                            leading: _SettingsIconBox(
                              icon: Icons.bar_chart_rounded,
                              backgroundColor: theme.appColors.navySoft,
                            ),
                            title: 'Budgets',
                            subtitle: 'Create and tune monthly caps',
                            onTap: () => context.push(AppRoutes.budgets),
                          ),
                          _SettingsActionRow(
                            leading: _SettingsIconBox(
                              icon: Icons.sell_outlined,
                              backgroundColor: theme.appColors.amberSoft,
                            ),
                            title: 'Categories',
                            subtitle: 'Manage labels for transactions',
                            onTap: () => context.push(AppRoutes.categories),
                          ),
                        ],
                      ),
                      _SettingsGroup(
                        title: 'Preferences',
                        children: [
                          _SettingsActionRow(
                            leading: _SettingsIconBox(
                              icon: Icons.psychology_alt_outlined,
                              backgroundColor: theme.appColors.amberSoft,
                            ),
                            title: 'AI Personality',
                            subtitle: userAsync.maybeWhen(
                              data: (user) =>
                                  '${_labelForAiIntensity(user.aiPersonalityIntensity)} intensity',
                              orElse: () => 'Balanced intensity',
                            ),
                            onTap: userAsync.maybeWhen(
                              data: (_) =>
                                  () => _showAiIntensityPicker(context, ref),
                              orElse: () => null,
                            ),
                          ),
                          _SettingsSwitchRow(
                            leading: _SettingsIconBox(
                              icon: Icons.location_on_outlined,
                              backgroundColor: theme.appColors.angelSoft,
                            ),
                            title: 'Smart Nearby Suggestions',
                            subtitle:
                                'Uses approximate location on this device only',
                            value: locationAssistance.isEnabled,
                            onChanged: (value) async {
                              final notifier =
                                  ref.read(locationAssistanceProvider.notifier);
                              if (value) {
                                await notifier.enableFromSettings();
                              } else {
                                await notifier.disableFromSettings();
                              }
                            },
                          ),
                          _SettingsActionRow(
                            leading: _SettingsIconBox(
                              icon: Icons.language,
                              backgroundColor: theme.appColors.navySoft,
                            ),
                            title: 'Locale & Number Format',
                            subtitle:
                                '${userPreferences.currency} · ${_regionFormatLabels[userPreferences.locale] ?? 'English'} numbers only',
                            onTap: () => _showLocalePicker(context, ref),
                          ),
                          _SettingsActionRow(
                            leading: _SettingsIconBox(
                              icon: Icons.currency_exchange,
                              backgroundColor: theme.appColors.navySoft,
                            ),
                            title: 'Default Currency',
                            subtitle: hasTransactionHistory
                                ? '${userPreferences.currency} · locked after first transaction'
                                : userPreferences.currency,
                            onTap: hasTransactionHistory
                                ? null
                                : () => _showCurrencyPicker(context, ref),
                            showChevron: !hasTransactionHistory,
                          ),
                          if (passkeysAvailable && sessionSupportsPasskeys)
                            _SettingsActionRow(
                              leading: _SettingsIconBox(
                                icon: Icons.fingerprint,
                                backgroundColor: theme.appColors.navySoft,
                              ),
                              title: _isRegisteringPasskey
                                  ? 'Setting Up Passkey...'
                                  : 'Set Up Passkey',
                              subtitle:
                                  'Use Face ID, fingerprint, or device unlock next time',
                              onTap: _isRegisteringPasskey
                                  ? null
                                  : () => _registerPasskey(context),
                              showChevron: !_isRegisteringPasskey,
                            ),
                        ],
                      ),
                      _SettingsGroup(
                        title: 'Subscription',
                        children: [
                          subAsync.when(
                            data: (status) => _PremiumRow(
                              isPremium: status.isPremium,
                              onTap: () => SubscriptionSheet.show(context),
                            ),
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: LinearProgressIndicator(),
                            ),
                            error: (_, __) => _SettingsActionRow(
                              leading: _SettingsIconBox(
                                icon: Icons.star_rounded,
                                backgroundColor: theme.appColors.amberSoft,
                              ),
                              title: 'Conscia Premium',
                              subtitle: 'Unable to load subscription',
                              onTap: () => ref.invalidate(subscriptionProvider),
                            ),
                          ),
                        ],
                      ),
                      if (ApiConstants.useMockAuth)
                        _SettingsGroup(
                          title: 'Developer',
                          children: [_DevUpgradeTile()],
                        ),
                      _SettingsGroup(
                        title: 'Data & Privacy',
                        children: [
                          _SettingsActionRow(
                            leading: _SettingsIconBox(
                              icon: Icons.download_rounded,
                              backgroundColor: theme.appColors.incomeSoft,
                              foregroundColor: theme.appColors.income,
                            ),
                            title: 'Download my data',
                            subtitle: 'Export your Conscia history as JSON',
                            onTap: () => _exportData(context, ref),
                          ),
                          _SettingsActionRow(
                            leading: _SettingsIconBox(
                              icon: Icons.delete_forever,
                              backgroundColor: theme.appColors.expenseSoft,
                              foregroundColor: theme.appColors.expense,
                            ),
                            title: 'Delete account',
                            subtitle: 'Permanently remove all your data',
                            titleColor: theme.appColors.expense,
                            onTap: () => _confirmDeleteAccount(context, ref),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _VersionFooter(
                    packageInfoAsync: ref.watch(_packageInfoProvider),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        } catch (e, s) {
          if (!context.mounted) return;
          final error = AppError.from(e, stackTrace: s, log: false);
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(error.userMessage)));
        }
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
        } catch (e, s) {
          if (!context.mounted) return;
          final error = AppError.from(e, stackTrace: s, log: false);
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(error.userMessage)));
        }
      },
    );
  }

  void _showAiIntensityPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(currentUserProvider).valueOrNull;
    if (current == null) return;

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            shrinkWrap: true,
            children: [
              const ConsciaSheetHandle(),
              const SizedBox(height: 18),
              const ConsciaSheetHeader(
                title: 'AI personality intensity',
                subtitle:
                    'Applies across Pre-Purchase, Reflection, and future AI guidance.',
              ),
              const SizedBox(height: 18),
              SingleSelectList<
                  ({String value, String label, String description})>(
                options: _aiIntensityOptions,
                value: _aiIntensityOptions.firstWhere(
                  (option) => option.value == current.aiPersonalityIntensity,
                  orElse: () => _aiIntensityOptions[1],
                ),
                titleBuilder: (option) => option.label,
                subtitleBuilder: (option) => option.description,
                onChanged: (option) async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await ref.read(userServiceProvider).updateProfile(
                          aiPersonalityIntensity: option.value,
                        );
                    ref.invalidate(currentUserProvider);
                  } catch (e, s) {
                    if (!context.mounted) return;
                    final error = AppError.from(e, stackTrace: s, log: false);
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                          SnackBar(content: Text(error.userMessage)));
                  }
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
    } catch (e, s) {
      messenger.clearSnackBars();
      final error = AppError.from(e, stackTrace: s);
      messenger.showSnackBar(
        SnackBar(content: Text(error.userMessage)),
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

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Delete this account?',
      message:
          'This permanently removes your account, transactions, budgets, AI interactions, receipts, and profile data. This can\'t be undone. Export your data first if you want a copy.',
      confirmLabel: 'Delete account',
    );
    if (!confirmed) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.delete('users/me');
      if (!context.mounted) return;
      ref.read(authProvider.notifier).logout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted.')),
      );
    } catch (e, s) {
      if (!context.mounted) return;
      final error = AppError.from(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Sign out?',
      message: 'You can sign back in anytime.',
      confirmLabel: 'Sign out',
    );
    if (!confirmed || !context.mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    context.go(AppRoutes.signIn);
  }

  String _labelForAiIntensity(String intensity) {
    for (final option in _aiIntensityOptions) {
      if (option.value == intensity) return option.label;
    }
    return 'Balanced';
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.mutedInk,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Material(
            key: ValueKey('settings-group-$title'),
            color: Colors.transparent,
            child: Column(children: _withDividers(children)),
          ),
        ],
      ),
    );
  }
}

class _SettingsEditorialHero extends StatelessWidget {
  const _SettingsEditorialHero({
    required this.user,
    required this.familySpace,
    required this.currencyCode,
    required this.locale,
    required this.onProfileTap,
    required this.onFamilyTap,
  });

  final UserProfile user;
  final FamilySpace? familySpace;
  final String currencyCode;
  final String locale;
  final VoidCallback onProfileTap;
  final VoidCallback onFamilyTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final workspaceLabel =
        familySpace == null ? 'Create or join' : familySpace!.name;

    return Container(
      key: const ValueKey('settings-editorial-hero'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppLayout.screenPadding,
        AppLayout.bleedingHeroTop(context),
        AppLayout.screenPadding,
        26,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.navySoft, colors.amberSoft],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SETTINGS HUB',
            style: textTheme.labelSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tune Conscia around you',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Keep privacy, household sharing, and money formatting in one calm place.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              EditorialHeroChip(label: '$currencyCode currency'),
              EditorialHeroChip(
                label:
                    '${_regionFormatLabels[locale]?.split(' / ').first ?? 'English'} numbers',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroShortcutPill(
                  key: const ValueKey('settings-hero-profile-shortcut'),
                  icon: AppIcons.person,
                  title: 'Profile',
                  subtitle: 'Personal workspace',
                  onTap: onProfileTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroShortcutPill(
                  key: const ValueKey('settings-hero-family-shortcut'),
                  icon: AppIcons.family,
                  title: 'Shared Conscia',
                  subtitle: workspaceLabel,
                  onTap: onFamilyTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsEditorialHeroSkeleton extends StatelessWidget {
  const _SettingsEditorialHeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return _SettingsEditorialHero(
      user: UserProfile(
        id: 'loading',
        email: 'loading@conscia.app',
        currencyCode: 'PHP',
        locale: 'en_US',
        createdAt: DateTime(2026),
        hasCompletedOnboarding: true,
      ),
      familySpace: null,
      currencyCode: 'PHP',
      locale: 'en_US',
      onProfileTap: () {},
      onFamilyTap: () {},
    );
  }
}

class _SettingsEditorialHeroFallback extends StatelessWidget {
  const _SettingsEditorialHeroFallback();

  @override
  Widget build(BuildContext context) {
    return _SettingsEditorialHero(
      user: UserProfile(
        id: 'unknown',
        email: 'Unable to load profile',
        currencyCode: 'PHP',
        locale: 'en_US',
        createdAt: DateTime(2026),
        hasCompletedOnboarding: true,
      ),
      familySpace: null,
      currencyCode: 'PHP',
      locale: 'en_US',
      onProfileTap: () {},
      onFamilyTap: () {},
    );
  }
}

class _HeroShortcutPill extends StatelessWidget {
  const _HeroShortcutPill({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: colors.surfaceRaised.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: colors.deepNavy),
              const SizedBox(width: 8),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 118),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.deepNavy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.mutedInk,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(AppIcons.chevronRight, size: 15, color: colors.softInk),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsIconBox extends StatelessWidget {
  const _SettingsIconBox({
    required this.icon,
    required this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Icon(icon, color: foregroundColor ?? colors.deepNavy, size: 22),
      ),
    );
  }
}

class _PremiumRow extends StatelessWidget {
  const _PremiumRow({
    required this.isPremium,
    required this.onTap,
  });

  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return _SettingsActionRow(
      leading: _SettingsIconBox(
        icon: Icons.star_rounded,
        backgroundColor: colors.amberSoft,
        foregroundColor: colors.amber,
      ),
      title: 'Conscia Premium',
      subtitle: isPremium ? 'Active' : 'Unlock receipt scan and family tools',
      onTap: onTap,
    );
  }
}

class _SettingsActionRow extends StatelessWidget {
  const _SettingsActionRow({
    required this.leading,
    required this.title,
    this.subtitle,
    this.onTap,
    this.titleColor,
    this.showChevron = true,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).appColors.mutedInk,
                              height: 1.25,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (showChevron)
                Icon(AppIcons.chevronRight,
                    color: Theme.of(context).appColors.border),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  const _SettingsSwitchRow({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
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
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s);
      messenger.showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
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

class _VersionFooter extends StatelessWidget {
  const _VersionFooter({required this.packageInfoAsync});

  final AsyncValue<PackageInfo> packageInfoAsync;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    final label = packageInfoAsync.whenOrNull(
      data: (info) => 'Conscia ${info.version} · build ${info.buildNumber}',
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        children: [
          Divider(color: colors.border),
          const SizedBox(height: 12),
          Text(
            label ?? 'Conscia',
            style: textTheme.bodySmall?.copyWith(
              color: colors.mutedInk,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

List<Widget> _withDividers(List<Widget> children) {
  return [
    for (var i = 0; i < children.length; i++) ...[
      children[i],
      if (i != children.length - 1) const Divider(height: 1),
    ],
  ];
}
