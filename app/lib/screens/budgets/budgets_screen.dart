import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/generated/app_constants.g.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/budget_providers.dart';
import '../../providers/subscription_provider.dart';
import '../../services/budget_service.dart';
import '../../services/subscription_service.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/budget_mix_visuals.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/scope_pill_switch.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/budget_form_sheet.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  final _scrollController = ScrollController();
  final _appBarScrollProgress = ValueNotifier<double>(0);
  String _scope = 'personal';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncAppBarProgressFromController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAppBarProgressFromController();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncAppBarProgressFromController);
    _scrollController.dispose();
    _appBarScrollProgress.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _syncAppBarProgressFromPixels(notification.metrics.pixels);
    }
    return false;
  }

  void _syncAppBarProgressFromController() {
    if (!_scrollController.hasClients) return;
    _syncAppBarProgressFromPixels(_scrollController.offset);
  }

  void _syncAppBarProgressFromPixels(double pixels) {
    final nextProgress = (pixels / 10).clamp(0.0, 1.0);
    if (_appBarScrollProgress.value != nextProgress) {
      _appBarScrollProgress.value = nextProgress;
    }
  }

  Future<void> _onRefresh(WidgetRef ref) {
    return ref.read(budgetListProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final budgetState = ref.watch(budgetListProvider);
    final hasPersonal = budgetState.budgets.any((budget) => !budget.isFamily);
    final hasFamily = budgetState.budgets.any((budget) => budget.isFamily);
    final effectiveScope = hasPersonal ? _scope : 'family';
    final visibleBudgets = hasFamily
        ? budgetState.budgets
            .where(
              (budget) => effectiveScope == 'family'
                  ? budget.isFamily
                  : !budget.isFamily,
            )
            .toList(growable: false)
        : budgetState.budgets;

    return ConsciaAppBarScrollScope(
      scrollProgress: _appBarScrollProgress,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: ConsciaAppBar(
          title: const Text('Budgets'),
          actions: [
            IconButton(
              tooltip: 'Add budget',
              icon: Icon(Icons.add_rounded, color: colors.deepNavy),
              onPressed: () => _onAddBudget(context, ref),
            ),
          ],
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.pageTop, colors.pageBottom],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () => _onRefresh(ref),
              child: CustomScrollView(
                key: const PageStorageKey('budgets-screen-scroll'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _BudgetsEditorialHero(
                      budgets: visibleBudgets,
                      showScopeSwitch: hasPersonal && hasFamily,
                      selectedScope: effectiveScope,
                      onScopeChanged: (value) =>
                          setState(() => _scope = value.toLowerCase()),
                    ),
                  ),
                  ..._buildBody(context, ref, budgetState, visibleBudgets),
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      key: ValueKey('budgets-bottom-nav-spacer'),
                      height: 88,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    WidgetRef ref,
    BudgetListState state,
    List<Budget> visibleBudgets,
  ) {
    if (state.isLoading && state.budgets.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverList.list(
            children: List.generate(
              3,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: BudgetListSkeletonCard(),
              ),
            ),
          ),
        ),
      ];
    }

    if (state.budgets.isEmpty || visibleBudgets.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: EmptyState(
              icon: Icons.pie_chart_outline_rounded,
              title: 'Budgets that match how you actually spend',
              subtitle:
                  'Create flexible monthly limits for the categories you care about most.',
              actionLabel: 'Create your first budget',
              onAction: () => _onAddBudget(context, ref),
            ),
          ),
        ),
      ];
    }

    return [
      const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 8),
        sliver: SliverToBoxAdapter(
          child: _SectionHeading(
            title: 'Active budgets',
            subtitle: 'Track how each category is pacing this month.',
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverToBoxAdapter(
          child: _BudgetLedger(
            budgets: visibleBudgets,
            onEdit: (budget) => BudgetFormSheet.show(context, existing: budget),
            onDelete: (budget) => _confirmDelete(context, ref, budget.id),
          ),
        ),
      ),
    ];
  }

  Future<void> _onAddBudget(BuildContext context, WidgetRef ref) async {
    final budgetState = ref.read(budgetListProvider);
    final subAsync = ref.read(subscriptionProvider);
    SubscriptionStatus? subscription = subAsync.valueOrNull;

    if (subscription == null) {
      try {
        subscription = await ref.read(subscriptionProvider.future);
      } catch (_) {
        subscription = null;
      }
      if (!context.mounted) return;
    }

    final isPremium = subscription?.isPremium ?? false;
    if (!isPremium &&
        budgetState.budgets.length >= FreemiumLimits.freeBudgetCategories) {
      PremiumUpgradeDialog.show(
        context,
        feature:
            'You\'ve reached the free tier limit of ${FreemiumLimits.freeBudgetCategories} budget categories.',
      );
      return;
    }

    if (context.mounted) BudgetFormSheet.show(context);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(budgetListProvider.notifier).delete(id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BudgetsEditorialHero extends StatefulWidget {
  const _BudgetsEditorialHero({
    required this.budgets,
    required this.showScopeSwitch,
    required this.selectedScope,
    required this.onScopeChanged,
  });

  final List<Budget> budgets;
  final bool showScopeSwitch;
  final String selectedScope;
  final ValueChanged<String> onScopeChanged;

  @override
  State<_BudgetsEditorialHero> createState() => _BudgetsEditorialHeroState();
}

class _BudgetsEditorialHeroState extends State<_BudgetsEditorialHero> {
  final _mixRailController = ScrollController();
  final _pillKeys = <GlobalKey>[];
  int? _calledOutMixIndex;
  int _shakeSerial = 0;

  @override
  void dispose() {
    _mixRailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final topInset = MediaQuery.paddingOf(context).top;
    final budgets = widget.budgets;
    final mix = _budgetMix(budgets);
    _syncPillKeys(mix.length);
    final totalSpent = budgets.fold<double>(0, (sum, b) => sum + b.spent);
    final totalLimit =
        budgets.fold<double>(0, (sum, b) => sum + b.monthlyLimit);
    final currencyCode = budgets.isEmpty ? 'PHP' : budgets.first.currencyCode;
    final ordered = [...budgets]
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final strongest = ordered.isEmpty ? null : ordered.first;
    final summary = strongest == null
        ? 'Start with a few calm monthly limits and let Conscia watch the pace.'
        : '${strongest.category} is currently carrying your strongest budget signal.';

    return Container(
      key: const ValueKey('budgets-editorial-hero'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.navySoft, colors.amberSoft],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUDGET PACE',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(
                        totalLimit,
                        currencyCode: currencyCode,
                      ),
                      style: textTheme.displaySmall?.copyWith(
                        color: colors.deepNavy,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.ink,
                        height: 1.35,
                      ),
                    ),
                    if (widget.showScopeSwitch) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 176,
                        child: ScopePillSwitch(
                          value: widget.selectedScope,
                          familyEnabled: true,
                          onChanged: widget.onScopeChanged,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              BudgetMixDonut(
                key: const ValueKey('budgets-hero-donut'),
                segments: _budgetSegments(mix, totalSpent),
                onSegmentTap: _callOutMixPill,
                center: _BudgetDonutCenter(
                  totalSpent: totalSpent,
                  currencyCode: currencyCode,
                ),
              ),
            ],
          ),
          if (budgets.isNotEmpty) ...[
            const SizedBox(height: 14),
            SingleChildScrollView(
              key: const ValueKey('budgets-mix-pill-rail'),
              controller: _mixRailController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                children: [
                  for (final entry in mix.indexed)
                    Padding(
                      padding: EdgeInsets.only(
                        right: entry.$1 == mix.length - 1 ? 0 : 8,
                      ),
                      child: BudgetMixPill(
                        key: _pillKeys[entry.$1],
                        index: entry.$1,
                        category: entry.$2.category,
                        share:
                            totalSpent <= 0 ? 0 : entry.$2.spent / totalSpent,
                        active: _calledOutMixIndex == entry.$1,
                        shakeSerial: _shakeSerial,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _syncPillKeys(int count) {
    while (_pillKeys.length < count) {
      _pillKeys.add(GlobalKey());
    }
    while (_pillKeys.length > count) {
      _pillKeys.removeLast();
    }
  }

  void _callOutMixPill(int index) {
    if (index < 0 || index >= _pillKeys.length) return;
    setState(() {
      _calledOutMixIndex = index;
      _shakeSerial++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _pillKeys[index].currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }

  List<Budget> _budgetMix(List<Budget> budgets) {
    final copy = [...budgets]..sort((a, b) => b.spent.compareTo(a.spent));
    return copy.toList(growable: false);
  }

  List<BudgetMixDonutSegment> _budgetSegments(
    List<Budget> budgets,
    double totalSpent,
  ) {
    if (totalSpent <= 0) return const [];
    return budgets
        .where((budget) => budget.spent > 0)
        .indexed
        .map(
          (entry) => BudgetMixDonutSegment(
            share: entry.$2.spent / totalSpent,
            color: BudgetMixPalette.staticColorFor(entry.$1),
          ),
        )
        .toList(growable: false);
  }
}

class _BudgetDonutCenter extends StatelessWidget {
  const _BudgetDonutCenter({
    required this.totalSpent,
    required this.currencyCode,
  });

  final double totalSpent;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              CurrencyFormatter.format(
                totalSpent,
                currencyCode: currencyCode,
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'used',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.mutedInk,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: colors.mutedInk,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: colors.mutedInk,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _BudgetLedger extends StatelessWidget {
  const _BudgetLedger({
    required this.budgets,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Budget> budgets;
  final ValueChanged<Budget> onEdit;
  final ValueChanged<Budget> onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final colorIndexByBudgetId = _colorIndexByBudgetId();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          top: BorderSide(color: colors.border),
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < budgets.length; index++) ...[
            _BudgetLedgerRow(
              budget: budgets[index],
              mixIndex: colorIndexByBudgetId[budgets[index].id] ?? index,
              onEdit: () => onEdit(budgets[index]),
              onDelete: () => onDelete(budgets[index]),
            ),
            if (index < budgets.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: colors.border,
              ),
          ],
        ],
      ),
    );
  }

  Map<String, int> _colorIndexByBudgetId() {
    final ordered = [...budgets]..sort((a, b) => b.spent.compareTo(a.spent));
    return {
      for (final entry in ordered.indexed) entry.$2.id: entry.$1,
    };
  }
}

class _BudgetLedgerRow extends StatelessWidget {
  const _BudgetLedgerRow({
    required this.budget,
    required this.mixIndex,
    required this.onEdit,
    required this.onDelete,
  });

  final Budget budget;
  final int mixIndex;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final pct = budget.percentage.clamp(0.0, 999.0);

    return InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BudgetCategoryGlyph(
              iconKey: ValueKey('budget-row-icon-${budget.id}'),
              category: budget.category,
              color: BudgetMixPalette.colorFor(mixIndex, context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              budget.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                color: colors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (budget.isFamily) const _FamilyBudgetPill(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(pct * 100).round()}%',
                        style: textTheme.titleSmall?.copyWith(
                          color: _budgetColor(colors, budget.percentage),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyFormatter.format(
                      budget.spent,
                      currencyCode: budget.currencyCode,
                    )} / ${CurrencyFormatter.format(
                      budget.monthlyLimit,
                      currencyCode: budget.currencyCode,
                    )}',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.mutedInk,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: budget.percentage.clamp(0.0, 1.0),
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _budgetColor(colors, budget.percentage),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _paceLabel(budget),
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.mutedInk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: 'Budget actions',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.more_horiz_rounded, color: colors.deepNavy),
              onPressed: () => _showRowActions(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showRowActions(BuildContext context) {
    final colors = Theme.of(context).appColors;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BudgetActionTile(
                icon: Icons.edit_rounded,
                label: 'Edit ${budget.category}',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onEdit();
                },
              ),
              _BudgetActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete budget',
                color: colors.expense,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onDelete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _budgetColor(AppColors colors, double percentage) {
    if (percentage >= 1) return colors.budgetDanger;
    if (percentage >= 0.8) return colors.budgetWarning;
    if (percentage >= 0.6) return colors.budgetCaution;
    return colors.budgetHealthy;
  }

  String _paceLabel(Budget budget) {
    if (budget.percentage >= 1) return 'Over pace';
    if (budget.percentage >= 0.8) return 'Close to cap';
    if (budget.percentage >= 0.6) return 'Watch this';
    return 'On pace';
  }
}

class _FamilyBudgetPill extends StatelessWidget {
  const _FamilyBudgetPill();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.familySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_rounded, size: 12, color: colors.family),
            const SizedBox(width: 4),
            Text(
              'Family budget',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.family,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetActionTile extends StatelessWidget {
  const _BudgetActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final foreground = color ?? colors.deepNavy;
    return ListTile(
      leading: Icon(icon, color: foreground),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
      onTap: onTap,
    );
  }
}
