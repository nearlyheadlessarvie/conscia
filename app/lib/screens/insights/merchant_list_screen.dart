import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/insights_models.dart';
import '../../providers/insights_provider.dart';

class MerchantListScreen extends ConsumerWidget {
  const MerchantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchantsAsync = ref.watch(insightsMerchantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Merchants')),
      body: merchantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load merchants.')),
        data: (merchants) {
          if (merchants.isEmpty) {
            return const Center(child: Text('No merchant data yet.'));
          }
          return ListView.builder(
            itemCount: merchants.length,
            itemBuilder: (context, i) => _MerchantTile(merchant: merchants[i]),
          );
        },
      ),
    );
  }
}

class _MerchantTile extends StatelessWidget {
  final MerchantStat merchant;

  const _MerchantTile({required this.merchant});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratePercent = (merchant.regretRate * 100).toStringAsFixed(0);
    final color = merchant.regretRate >= 0.6
        ? colors.error
        : merchant.regretRate >= 0.4
            ? colors.tertiary
            : colors.primary;

    return ListTile(
      title: Text(merchant.merchant),
      subtitle: Text('${merchant.visitCount} visits · last ${merchant.lastVisitDate}'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$ratePercent%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('regret', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11)),
        ],
      ),
      onTap: () => context.push('/insights/merchants/${merchant.merchant}'),
    );
  }
}
