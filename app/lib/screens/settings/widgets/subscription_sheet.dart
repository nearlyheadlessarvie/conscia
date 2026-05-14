import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../providers/iap_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/iap_service.dart';

class SubscriptionSheet {
  SubscriptionSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) =>
            _SubscriptionSheetBody(scrollController: controller),
      ),
    );
  }
}

class _SubscriptionSheetBody extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _SubscriptionSheetBody({required this.scrollController});

  @override
  ConsumerState<_SubscriptionSheetBody> createState() =>
      _SubscriptionSheetBodyState();
}

class _SubscriptionSheetBodyState
    extends ConsumerState<_SubscriptionSheetBody> {
  StreamSubscription<IAPStatus>? _iapSub;
  bool _waitingForPurchase = false;
  bool _isRestore = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    final service = ref.read(iapServiceProvider);
    _iapSub = service.statusStream.listen(_onIAPStatus);
  }

  @override
  void dispose() {
    _iapSub?.cancel();
    super.dispose();
  }

  Future<void> _onIAPStatus(IAPStatus status) async {
    if (!mounted || !_waitingForPurchase) return;

    switch (status.state) {
      case IAPState.available:
        setState(() {
          _waitingForPurchase = false;
          _error = null;
          _notice = null;
        });
        ref.invalidate(subscriptionProvider);
        final sub = await ref.read(subscriptionProvider.future);
        if (!mounted) return;

        if (sub.isPremium) {
          final messenger = ScaffoldMessenger.of(context);
          Navigator.of(context).pop();
          messenger.showSnackBar(
            const SnackBar(content: Text('Welcome to Conscia Premium!')),
          );
        } else if (_isRestore) {
          setState(() {
            _notice = 'No previous purchases found.';
          });
        }
        _isRestore = false;

      case IAPState.error:
        setState(() {
          _waitingForPurchase = false;
          _isRestore = false;
          _error = status.errorMessage;
        });

      case IAPState.purchasing:
      case IAPState.uninitialized:
      case IAPState.unavailable:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final iapAsync = ref.watch(iapStatusProvider);
    final priceLabel = iapAsync.whenOrNull(
      data: (status) => status.product?.price,
    );
    final subscription = ref.watch(subscriptionProvider).valueOrNull;
    final isCurrentPremium = subscription?.isPremium ?? false;
    final expiresAt = subscription?.expiresAt;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isCurrentPremium
              ? 'Manage Conscia Premium'
              : 'Unlock Conscia Premium',
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildComparisonTable(
          theme,
          textTheme,
          isPremiumActive: isCurrentPremium,
        ),
        const SizedBox(height: 32),
        if (isCurrentPremium) ...[
          Text(
            expiresAt != null
                ? 'Premium access stays active until ${_formatDate(expiresAt)}'
                : 'Premium access is currently active.',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'You can cancel renewal in the store and keep Premium until your paid period ends.',
            style: textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          Text(
            priceLabel != null ? '$priceLabel / month' : '\$4.99 / month',
            style:
                textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (priceLabel == null && !ApiConstants.useMockAuth)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Price loading from store...',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
        const SizedBox(height: 24),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _notice!,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        FilledButton(
          onPressed: _waitingForPurchase
              ? null
              : isCurrentPremium
                  ? _manageSubscription
                  : _subscribe,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _waitingForPurchase
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  isCurrentPremium ? 'Manage Subscription' : 'Subscribe Now'),
        ),
        const SizedBox(height: 12),
        if (!isCurrentPremium)
          Center(
            child: TextButton(
              onPressed: _waitingForPurchase ? null : _restorePurchases,
              child: const Text('Restore Purchases'),
            ),
          ),
      ],
    );
  }

  Widget _buildComparisonTable(
    ThemeData theme,
    TextTheme textTheme, {
    required bool isPremiumActive,
  }) {
    final features = [
      ('Transactions', 'Unlimited', 'Unlimited'),
      ('Budgets', '3', 'Unlimited'),
      ('AI Assists', '5/month', 'Unlimited'),
      ('Reflections', '10/month', 'Unlimited'),
      ('Receipt Scanner', '—', 'Included'),
      ('Multi-Currency', '1', 'Unlimited'),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1.5),
          2: FlexColumnWidth(1.5),
        },
        children: [
          TableRow(
            children: [
              const SizedBox.shrink(),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanHeader(
                  label: 'Free',
                  isActive: !isPremiumActive,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanHeader(
                  label: 'Premium',
                  isActive: isPremiumActive,
                ),
              ),
            ],
          ),
          ...features.map(
            (f) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(f.$1, style: textTheme.bodyMedium),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: _PlanValueCell(
                    value: f.$2,
                    isActive: !isPremiumActive,
                    emphasize: false,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: _PlanValueCell(
                    value: f.$3,
                    isActive: isPremiumActive,
                    emphasize: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe() async {
    if (ApiConstants.useMockAuth) {
      if (!mounted) return;
      setState(() {
        _notice =
            'Subscription purchases are not available in development mode. Deploy to a device with store access to test.';
      });
      return;
    }

    setState(() {
      _waitingForPurchase = true;
      _error = null;
      _notice = null;
    });

    try {
      final iapService = ref.read(iapServiceProvider);
      final started = await iapService.purchaseSubscription();

      if (!started) {
        if (!mounted) return;
        setState(() {
          _waitingForPurchase = false;
          _error = iapService.status.product == null
              ? 'Product not configured in store yet. Set up "$kPremiumMonthlyId" in App Store Connect / Play Console.'
              : 'Could not start purchase flow.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _waitingForPurchase = false;
        _error = 'Purchase failed: $e';
      });
    }
  }

  Future<void> _restorePurchases() async {
    if (ApiConstants.useMockAuth) {
      if (!mounted) return;
      setState(() {
        _notice =
            'Purchase restore is not available in development mode. Deploy to a device with store access to test.';
      });
      return;
    }

    setState(() {
      _waitingForPurchase = true;
      _isRestore = true;
      _error = null;
      _notice = null;
    });

    try {
      final iapService = ref.read(iapServiceProvider);
      await iapService.restorePurchases();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _waitingForPurchase = false;
        _error = 'Restore failed: $e';
      });
    }
  }

  Future<void> _manageSubscription() async {
    if (ApiConstants.useMockAuth) {
      setState(() {
        _notice =
            'Subscription management is not available in development mode. On a live device, this opens the App Store or Play Store so you can cancel renewal while keeping Premium until the expiry date.';
      });
      return;
    }

    final iapService = ref.read(iapServiceProvider);
    final launched = await iapService.openManageSubscriptions();
    if (!mounted) return;

    if (!launched) {
      setState(() {
        _error =
            'Could not open the store subscription settings. Please manage your subscription directly in the App Store or Play Store.';
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _PlanHeader extends StatelessWidget {
  final String label;
  final bool isActive;

  const _PlanHeader({
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive) ...[
              Icon(
                Icons.check_circle,
                size: 14,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanValueCell extends StatelessWidget {
  final String value;
  final bool isActive;
  final bool emphasize;

  const _PlanValueCell({
    required this.value,
    required this.isActive,
    required this.emphasize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.55)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value,
        style: textTheme.bodySmall?.copyWith(
          color: emphasize
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: isActive || emphasize ? FontWeight.w600 : FontWeight.w400,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
