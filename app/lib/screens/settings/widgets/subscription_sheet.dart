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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No previous purchases found.')),
          );
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
          'Unlock Conscia Premium',
          style:
              textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildComparisonTable(theme, textTheme),
        const SizedBox(height: 32),
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
        const SizedBox(height: 24),
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
          onPressed: _waitingForPurchase ? null : _subscribe,
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
              : const Text('Subscribe Now'),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: _waitingForPurchase ? null : _restorePurchases,
            child: const Text('Restore Purchases'),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable(ThemeData theme, TextTheme textTheme) {
    final features = [
      ('Transactions', 'Unlimited', 'Unlimited'),
      ('Budgets', '3', 'Unlimited'),
      ('AI Assists', '5/month', 'Unlimited'),
      ('Reflections', '10/month', 'Unlimited'),
      ('Receipt Scanner', '—', 'Included'),
      ('Multi-Currency', '1', 'Unlimited'),
    ];

    return Table(
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
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Free',
                  style: textTheme.labelLarge,
                  textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Premium',
                  style: textTheme.labelLarge,
                  textAlign: TextAlign.center),
            ),
          ],
        ),
        ...features.map((f) => TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(f.$1, style: textTheme.bodyMedium),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    f.$2,
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    f.$3,
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )),
      ],
    );
  }

  Future<void> _subscribe() async {
    if (ApiConstants.useMockAuth) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'IAP not available in development mode. Deploy to a device with store access to test.'),
        ),
      );
      return;
    }

    setState(() {
      _waitingForPurchase = true;
      _error = null;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'IAP not available in development mode. Deploy to a device with store access to test.'),
        ),
      );
      return;
    }

    setState(() {
      _waitingForPurchase = true;
      _isRestore = true;
      _error = null;
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
}
