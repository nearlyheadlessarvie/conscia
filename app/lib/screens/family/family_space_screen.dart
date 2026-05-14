import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/family_overview.dart';
import '../../models/family_member.dart';
import '../../models/family_space.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/skeleton_loader.dart';

class FamilySpaceScreen extends ConsumerWidget {
  const FamilySpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familySpace = ref.watch(familySpaceProvider);

    return HeroScreenScaffold(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      appBar: const ConsciaAppBar(title: Text('Shared Conscia')),
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
          'Create one household space, invite family members, then share only records you explicitly mark as Family.',
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
                'Shared budgets, household activity, and family-aware insights.',
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
    final overview = ref.watch(familyOverviewProvider);
    final members = ref.watch(familyMembersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FamilyEditorialHeader(
          space: space,
          memberCount: members.valueOrNull?.length,
        ),
        overview.when(
          data: (data) => Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _FamilyOverviewDetails(
              overview: data,
              membersAsync: members,
              role: space.role,
            ),
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

class _FamilyEditorialHeader extends StatelessWidget {
  const _FamilyEditorialHeader({
    required this.space,
    required this.memberCount,
  });

  final FamilySpace space;
  final int? memberCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final countText = memberCount == null
        ? 'Members'
        : '$memberCount ${memberCount == 1 ? 'member' : 'members'}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.familySoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.family.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Center(
          child: Column(
            children: [
              const Text('👨‍👩‍👧', style: TextStyle(fontSize: 38)),
              const SizedBox(height: 12),
              Text(
                space.name,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.family,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$countText · You are the ${_roleLabel(space.role)}',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: colors.mutedInk),
              ),
              const SizedBox(height: 12),
              Text(
                _roleLabel(space.role),
                style: textTheme.labelSmall?.copyWith(
                  color: colors.deepNavy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyOverviewDetails extends StatelessWidget {
  const _FamilyOverviewDetails({
    required this.overview,
    required this.membersAsync,
    required this.role,
  });

  final FamilyOverview overview;
  final AsyncValue<List<FamilyMember>> membersAsync;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Shared budgets',
          action: 'Manage ›',
          onTap: () => context.push(AppRoutes.budgets),
        ),
        const SizedBox(height: 10),
        overview.budgets.isEmpty
            ? const FeedCard(child: Text('No shared budgets yet.'))
            : FeedCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: _separated(
                    overview.budgets
                        .map((budget) => _BudgetOverviewRow(budget: budget)),
                  ),
                ),
              ),
        const SizedBox(height: 24),
        const _SectionHeader(title: 'Recent family activity'),
        const SizedBox(height: 10),
        overview.recentActivity.isEmpty
            ? const FeedCard(child: Text('No family activity yet.'))
            : FeedCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: _separated(
                    overview.recentActivity.map(
                      (activity) => _FamilyActivityRow(activity: activity),
                    ),
                  ),
                ),
              ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Members',
          action: 'Manage ›',
          onTap: () => context.push(AppRoutes.familyMembers),
        ),
        const SizedBox(height: 10),
        membersAsync.when(
          data: (members) => members.isEmpty
              ? const FeedCard(child: Text('No family members yet.'))
              : FeedCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: _separated(
                      members.take(4).map((member) => _MemberOverviewRow(
                            member: member,
                          )),
                    ),
                  ),
                ),
          loading: () => const SkeletonCard(),
          error: (_, __) =>
              const FeedCard(child: Text('Unable to load members.')),
        ),
        const SizedBox(height: 12),
        const _PrivacyNote(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.action,
    this.onTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.ink,
                ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: colors.deepNavy,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(action!),
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
    final colors = theme.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const _FamilyIcon(icon: Icons.shopping_cart_outlined),
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
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.income,
              fontWeight: FontWeight.w800,
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
    final colors = theme.appColors;
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
            '${isExpense ? '-' : '+'}${activity.currencyCode} ${_amount(activity.amount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isExpense ? colors.expense : colors.income,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberOverviewRow extends StatelessWidget {
  const _MemberOverviewRow({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.navySoft,
            child: Text(
              member.initials,
              style: textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  style: textTheme.bodySmall?.copyWith(color: colors.mutedInk),
                ),
              ],
            ),
          ),
          _RolePill(role: member.role),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: role.toLowerCase() == 'contributor'
            ? colors.angelSoft
            : colors.navySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          _roleLabel(role),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: role.toLowerCase() == 'contributor'
                    ? colors.angelAccent
                    : colors.deepNavy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.angelSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.angelAccent.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Text('🔒', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Personal stays personal unless you mark it Family.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.deepNavy,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyIcon extends StatelessWidget {
  const _FamilyIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.incomeSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(icon, size: 20, color: colors.family),
      ),
    );
  }
}

String _amount(double value) => NumberFormat('#,##0.00').format(value);

String _roleLabel(String role) {
  if (role.isEmpty) return 'Member';
  return '${role[0].toUpperCase()}${role.substring(1).toLowerCase()}';
}

List<Widget> _separated(Iterable<Widget> children) {
  final items = children.toList();
  return [
    for (var i = 0; i < items.length; i++) ...[
      items[i],
      if (i != items.length - 1) const Divider(height: 1),
    ],
  ];
}
