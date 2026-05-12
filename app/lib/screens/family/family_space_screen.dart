import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../models/family_overview.dart';
import '../../models/family_space.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/skeleton_loader.dart';

class FamilySpaceScreen extends ConsumerWidget {
  const FamilySpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familySpace = ref.watch(familySpaceProvider);

    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Shared Conscia')),
      child: familySpace.when(
        data: (space) => space == null
            ? const _NoFamilySpaceView()
            : _FamilySpaceOverview(space: space),
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonCard(),
            SizedBox(height: 14),
            SkeletonCard(),
          ],
        ),
        error: (_, __) => FeedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to load Family Space'),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(familySpaceProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoFamilySpaceView extends StatelessWidget {
  const _NoFamilySpaceView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Plan together without exposing everything.',
            style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Create one household space, invite family members, then explicitly import the records you want to share.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 18),
        FeedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(AppIcons.family, size: 36),
              const SizedBox(height: 12),
              Text(
                'Shared budgets, recurring contributions, and family-aware insights.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () => context.push(AppRoutes.familySetup),
                icon: const Icon(Icons.add),
                label: const Text('Create Family Space'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilySpaceOverview extends ConsumerWidget {
  const _FamilySpaceOverview({required this.space});

  final FamilySpace space;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final overview = ref.watch(familyOverviewProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedCard(
          child: Row(
            children: [
              CircleAvatar(
                child: Text(space.name.isEmpty ? '?' : space.name[0]),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(space.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      '${space.role} · ${space.currencyCode}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (space.isReadOnly)
                const Tooltip(
                  message: 'Read-only while Premium is inactive',
                  child: Icon(Icons.lock_outline),
                ),
            ],
          ),
        ),
        overview.when(
          data: (data) => Padding(
            padding: const EdgeInsets.only(top: 18),
            child: _FamilyOverviewDetails(overview: data),
          ),
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 14),
            child: Column(
              children: [
                SkeletonCard(),
                SizedBox(height: 14),
                SkeletonCard(),
              ],
            ),
          ),
          error: (_, __) => Padding(
            padding: const EdgeInsets.only(top: 14),
            child: FeedCard(
              child: Row(
                children: [
                  const Expanded(child: Text('Unable to load shared activity')),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(familyOverviewProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FamilyOverviewDetails extends StatelessWidget {
  const _FamilyOverviewDetails({required this.overview});

  final FamilyOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScreenSection(
          title: 'Shared budgets',
          child: overview.budgets.isEmpty
              ? const FeedCard(child: Text('No shared budgets yet.'))
              : FeedCard(
                  child: Column(
                    children: overview.budgets
                        .map((budget) => _BudgetOverviewRow(budget: budget))
                        .toList(),
                  ),
                ),
        ),
        ScreenSection(
          title: 'Recent family activity',
          child: overview.recentActivity.isEmpty
              ? const FeedCard(child: Text('No family activity yet.'))
              : FeedCard(
                  child: Column(
                    children: overview.recentActivity
                        .map((activity) =>
                            _FamilyActivityRow(activity: activity))
                        .toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _BudgetOverviewRow extends StatelessWidget {
  const _BudgetOverviewRow({required this.budget});

  final FamilyBudgetOverview budget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const _FamilyIcon(icon: Icons.account_balance_wallet_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(budget.category, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '${budget.currencyCode} ${_amount(budget.spentThisMonth)} / ${_amount(budget.monthlyLimit)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${budget.usagePercent}%',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyActivityRow extends StatelessWidget {
  const _FamilyActivityRow({required this.activity});

  final FamilyActivity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpense = activity.type.toLowerCase() == 'expense';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _FamilyIcon(
            icon: isExpense
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '${activity.category} · ${DateFormat.MMMd().format(activity.date)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${activity.currencyCode} ${_amount(activity.amount)}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyIcon extends StatelessWidget {
  const _FamilyIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 18,
      backgroundColor: colors.primaryContainer.withValues(alpha: 0.45),
      child: Icon(icon, size: 18, color: colors.primary),
    );
  }
}

String _amount(double value) => NumberFormat('#,##0.00').format(value);
