import 'package:flutter/material.dart';

class SubscriptionSheet extends StatefulWidget {
  const SubscriptionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
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

  @override
  State<SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<SubscriptionSheet> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _SubscriptionSheetBody extends StatefulWidget {
  final ScrollController scrollController;

  const _SubscriptionSheetBody({required this.scrollController});

  @override
  State<_SubscriptionSheetBody> createState() => _SubscriptionSheetBodyState();
}

class _SubscriptionSheetBodyState extends State<_SubscriptionSheetBody> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
          style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        _buildComparisonTable(theme, textTheme),
        const SizedBox(height: 32),
        Text(
          '\$4.99 / month',
          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _subscribe,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.onSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          child: _isLoading
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
            onPressed: _restorePurchases,
            child: const Text('Restore Purchases'),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonTable(ThemeData theme, TextTheme textTheme) {
    final features = [
      ('Transactions', '50/month', 'Unlimited'),
      ('Budgets', '3', 'Unlimited'),
      ('AI Advisor', 'Basic', 'Advanced'),
      ('Receipt Scanner', '—', 'Included'),
      ('Export Data', '—', 'CSV & PDF'),
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
              child: Text('Free', style: textTheme.labelLarge, textAlign: TextAlign.center),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Premium', style: textTheme.labelLarge, textAlign: TextAlign.center),
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
    setState(() => _isLoading = true);
    // TODO: integrate with in-app purchase flow
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _restorePurchases() async {
    // TODO: integrate with in-app purchase restore
  }
}
