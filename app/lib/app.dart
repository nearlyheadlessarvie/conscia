import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/health_provider.dart';
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
  int _secondsUntilRetry = HealthStatusNotifier.autoRetryInterval.inSeconds;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _secondsUntilRetry <= 1
          ? HealthStatusNotifier.autoRetryInterval.inSeconds
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
    final state = ref.watch(healthStatusProvider);

    ref.listen(healthStatusProvider, (previous, next) {
      if (previous?.lastChecked != next.lastChecked) {
        setState(
          () => _secondsUntilRetry =
              HealthStatusNotifier.autoRetryInterval.inSeconds,
        );
      }
    });

    if (!state.isOffline) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

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
                      Icons.cloud_off,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Device Offline',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conscia cannot reach the internet right now. We will retry automatically.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(healthStatusProvider.notifier).refresh(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry Now'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Retrying in ${_secondsUntilRetry}s',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
