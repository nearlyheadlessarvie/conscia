import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/constants/app_icons.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/app_availability_provider.dart';
import 'providers/iap_provider.dart';
import 'providers/user_provider.dart';
import 'services/deep_link_service.dart';
import 'services/push_notification_service.dart';

class ConsciaApp extends ConsumerWidget {
  const ConsciaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Eagerly initialize IAP so the purchase stream listener catches
    // deferred/pending purchases from interrupted flows.
    ref.watch(iapStatusProvider);

    return DeepLinkBootstrapper(
      router: router,
      child: PushNotificationBootstrapper(
        child: MaterialApp.router(
          title: 'Conscia',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          routerConfig: router,
          builder: (context, child) {
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const _AuthRestoreBlocker(),
                const _OfflineBlocker(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _OfflineBlocker extends ConsumerStatefulWidget {
  const _OfflineBlocker();

  @override
  ConsumerState<_OfflineBlocker> createState() => _OfflineBlockerState();
}

class _OfflineBlockerState extends ConsumerState<_OfflineBlocker> {
  Timer? _countdownTimer;
  int _secondsUntilRetry = AppAvailabilityNotifier.autoRetryInterval.inSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _secondsUntilRetry <= 1
          ? AppAvailabilityNotifier.autoRetryInterval.inSeconds
          : _secondsUntilRetry - 1;
      setState(() => _secondsUntilRetry = next);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _countdownTimer?.cancel();
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _OfflineBlockerLifecycleObserver(
    onLifecycleChanged: (state) async {
      if (!mounted) return;
      final notifier = ref.read(appAvailabilityProvider.notifier);
      if (state == AppLifecycleState.resumed) {
        await notifier.setForegrounded(true);
        return;
      }

      if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden) {
        await notifier.setForegrounded(false);
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appAvailabilityProvider);

    ref.listen(appAvailabilityProvider, (previous, next) {
      if (previous?.lastChecked != next.lastChecked) {
        setState(
          () => _secondsUntilRetry =
              AppAvailabilityNotifier.autoRetryInterval.inSeconds,
        );
      }
    });

    if (!state.isBlocked) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final blocker = _BlockerContent.fromState(state);

    return Positioned.fill(
      child: ColoredBox(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcons.icon(
                      blocker.icon,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      blocker.title,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      blocker.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (state.isUpdateRequired &&
                        state.availableVersion != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Store version ${state.availableVersion} is required to continue.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () async {
                        if (state.isUpdateRequired && state.updateUrl != null) {
                          await launchUrl(
                            Uri.parse(state.updateUrl!),
                            mode: LaunchMode.externalApplication,
                          );
                          return;
                        }
                        await ref
                            .read(appAvailabilityProvider.notifier)
                            .refresh();
                      },
                      icon: AppIcons.icon(
                        state.isUpdateRequired
                            ? AppIconKey.serviceHealth
                            : AppIconKey.refresh,
                        color: theme.colorScheme.onPrimary,
                      ),
                      label: Text(
                        state.isUpdateRequired ? 'Update Now' : 'Retry Now',
                      ),
                    ),
                    if (!state.isUpdateRequired) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Retrying in ${_secondsUntilRetry}s',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthRestoreBlocker extends ConsumerWidget {
  const _AuthRestoreBlocker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userAsync = authState.isAuthenticated
        ? ref.watch(currentUserProvider)
        : null;
    final shouldBlock =
        authState.isRestoringSession || (authState.isAuthenticated && userAsync?.isLoading == true);
    if (!shouldBlock) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Positioned.fill(
      child: ColoredBox(
        color: theme.scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Conscia',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBlockerLifecycleObserver extends WidgetsBindingObserver {
  _OfflineBlockerLifecycleObserver({required this.onLifecycleChanged});

  final Future<void> Function(AppLifecycleState state) onLifecycleChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(onLifecycleChanged(state));
  }
}

class _BlockerContent {
  const _BlockerContent({
    required this.icon,
    required this.title,
    required this.message,
  });

  final AppIconKey icon;
  final String title;
  final String message;

  factory _BlockerContent.fromState(AppAvailabilityState state) {
    switch (state.issue) {
      case AvailabilityIssue.deviceOffline:
        return const _BlockerContent(
          icon: AppIconKey.offlineDevice,
          title: 'Device Offline',
          message:
              'Conscia cannot reach the internet right now. We will retry automatically.',
        );
      case AvailabilityIssue.apiUnavailable:
        return const _BlockerContent(
          icon: AppIconKey.offlineCloud,
          title: 'Conscia Unavailable',
          message:
              'Your device is online, but the Conscia is temporarily unavailable.',
        );
      case AvailabilityIssue.updateRequired:
        return const _BlockerContent(
          icon: AppIconKey.serviceHealth,
          title: 'Update Required',
          message:
              'A newer version of Conscia is available in the store and is required before you can continue.',
        );
      case AvailabilityIssue.none:
        return const _BlockerContent(
          icon: AppIconKey.verified,
          title: '',
          message: '',
        );
    }
  }
}
