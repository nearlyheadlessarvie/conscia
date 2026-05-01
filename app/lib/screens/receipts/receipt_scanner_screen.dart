import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/subscription_provider.dart';
import 'widgets/premium_gate.dart';

class ReceiptScannerScreen extends ConsumerWidget {
  const ReceiptScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Receipt')),
      body: subAsync.when(
        data: (status) {
          if (!status.isPremium) {
            return const PremiumGate(
              icon: Icons.camera_alt,
              headline: 'Receipt Scanner',
              description:
                  'Automatically extract transaction details from receipts '
                  'using AI. Available with Conscia Premium.',
            );
          }
          return _buildPremiumContent(context);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Unable to check subscription status'),
        ),
      ),
    );
  }

  Widget _buildPremiumContent(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.camera_alt,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Camera functionality coming soon',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
