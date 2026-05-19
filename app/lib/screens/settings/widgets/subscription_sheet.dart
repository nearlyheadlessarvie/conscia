import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
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
    final colors = theme.appColors;
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
      padding: EdgeInsets.zero,
      children: [
        _SubscriptionHero(isPremium: isCurrentPremium, expiresAt: expiresAt),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildComparisonList(theme, textTheme, isPremiumActive: isCurrentPremium),
              const SizedBox(height: 24),
              if (!isCurrentPremium) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      priceLabel ?? '\$4.99',
                      style: textTheme.displaySmall?.copyWith(
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ month',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.mutedInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (priceLabel == null && !ApiConstants.useMockAuth)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Price loading from store...',
                      style: textTheme.bodySmall?.copyWith(color: colors.mutedInk),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Cancel anytime from your App Store or Play Store settings.',
                  style: textTheme.bodySmall?.copyWith(color: colors.mutedInk, height: 1.35),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
              if (_notice != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.navySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _notice!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w600,
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
                      color: colors.expenseSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.expense,
                        fontWeight: FontWeight.w600,
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
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: colors.amber,
                  foregroundColor: colors.ink,
                  shape: const StadiumBorder(),
                  textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                child: _waitingForPurchase
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isCurrentPremium ? 'Manage Subscription' : 'Subscribe Now'),
              ),
              if (!isCurrentPremium) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _waitingForPurchase ? null : _restorePurchases,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.mutedInk,
                      textStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Restore Purchases'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonList(
    ThemeData theme,
    TextTheme textTheme, {
    required bool isPremiumActive,
  }) {
    final colors = theme.appColors;
    final features = [
      ('Transactions', 'Unlimited', 'Unlimited'),
      ('Budgets', '3', 'Unlimited'),
      ('AI Assists', '5/month', 'Unlimited'),
      ('Reflections', '10/month', 'Unlimited'),
      ('Receipt Scanner', '—', 'Included'),
      ('Multi-Currency', '1', 'Unlimited'),
    ];

    return Column(
      key: const ValueKey('subscription-comparison-list'),
      children: [
        for (var i = 0; i < features.length; i++) ...[
          _PlanFeatureRow(
            label: features[i].$1,
            freeValue: features[i].$2,
            premiumValue: features[i].$3,
          ),
          if (i != features.length - 1)
            Divider(height: 1, color: colors.border),
        ],
      ],
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

}

class _SubscriptionHero extends StatelessWidget {
  const _SubscriptionHero({required this.isPremium, required this.expiresAt});

  final bool isPremium;
  final DateTime? expiresAt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.deepNavy, Color.lerp(colors.deepNavy, colors.amber, 0.18)!],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.amber.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.workspace_premium_rounded, color: colors.amber, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            isPremium ? 'Conscia Premium' : 'Unlock Conscia Premium',
            style: textTheme.headlineSmall?.copyWith(
              color: colors.paper,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          if (isPremium) ...[
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: colors.amber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.amber.withValues(alpha: 0.4)),
              ),
              child: Text(
                expiresAt != null
                    ? 'Active · renews ${_fmt(expiresAt!)}'
                    : 'Active',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.amber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else ...[
            Text(
              'Unlimited everything. No compromises.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.paper.withValues(alpha: 0.7),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}

class _PlanFeatureRow extends StatelessWidget {
  const _PlanFeatureRow({
    required this.label,
    required this.freeValue,
    required this.premiumValue,
  });

  final String label;
  final String freeValue;
  final String premiumValue;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            flex: 12,
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              freeValue,
              style: textTheme.bodySmall?.copyWith(
                color: colors.softInk,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colors.amberSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                premiumValue,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
