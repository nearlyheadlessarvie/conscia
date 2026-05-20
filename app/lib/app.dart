import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/app_availability_provider.dart';
import 'providers/iap_provider.dart';
import 'services/push_notification_service.dart';

class ConsciaApp extends ConsumerWidget {
  const ConsciaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // Eagerly initialize IAP so the purchase stream listener catches
    // deferred/pending purchases from interrupted flows.
    ref.watch(iapStatusProvider);

    return PushNotificationBootstrapper(
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
              const _OfflineBlocker(),
            ],
          );
        },
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
    _countdownTimer?.cancel();
    super.dispose();
  }

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
                    Icon(
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
                      icon: Icon(
                        state.isUpdateRequired
                            ? Icons.system_update
                            : Icons.refresh,
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

class _BlockerContent {
  const _BlockerContent({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  factory _BlockerContent.fromState(AppAvailabilityState state) {
    switch (state.issue) {
      case AvailabilityIssue.deviceOffline:
        return const _BlockerContent(
          icon: Icons.cloud_off,
          title: 'Device Offline',
          message:
              'Conscia cannot reach the internet right now. We will retry automatically.',
        );
      case AvailabilityIssue.apiUnavailable:
        return const _BlockerContent(
          icon: Icons.cloud_off_outlined,
          title: 'Conscia Unavailable',
          message:
              'Your device is online, but the Conscia is temporarily unavailable.',
        );
      case AvailabilityIssue.updateRequired:
        return const _BlockerContent(
          icon: Icons.system_update,
          title: 'Update Required',
          message:
              'A newer version of Conscia is available in the store and is required before you can continue.',
        );
      case AvailabilityIssue.none:
        return const _BlockerContent(
          icon: Icons.check_circle,
          title: '',
          message: '',
        );
    }
  }
}
