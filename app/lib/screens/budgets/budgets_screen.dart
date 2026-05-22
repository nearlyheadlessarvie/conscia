import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/budget_providers.dart';
import '../../services/budget_service.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/budget_mix_visuals.dart';
import '../../widgets/conscia_confirm_sheet.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/horizontal_edge_fade.dart';
import '../../widgets/scope_pill_switch.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/swipe_action_tile.dart';
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
                      height: 32,
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
            onDelete: (budget) => _confirmDelete(context, ref, budget),
          ),
        ),
      ),
    ];
  }

  Future<void> _onAddBudget(BuildContext context, WidgetRef ref) async {
    if (context.mounted) BudgetFormSheet.show(context);
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Budget budget) async {
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Delete ${budget.category} budget?',
      message: "This can't be undone.",
      confirmLabel: 'Delete budget',
    );
    if (!confirmed) return;
    await ref.read(budgetListProvider.notifier).delete(budget.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Budget deleted.')),
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
        : totalSpent <= 0
            ? 'Your budgets are ready. Spending will start shaping this story.'
            : '${strongest.category} is currently carrying your strongest budget signal.';

    return Container(
      key: const ValueKey('budgets-editorial-hero'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppLayout.screenPadding,
        AppLayout.budgetHeroTop(context),
        AppLayout.screenPadding,
        AppLayout.heroBottomPadding,
      ),
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
            HorizontalEdgeFade(
              child: SingleChildScrollView(
                key: const ValueKey('budgets-mix-pill-rail'),
                controller: _mixRailController,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.hardEdge,
                child: Row(
                  children: [
                    for (final entry in mix.indexed)
                      Padding(
                        padding: EdgeInsets.only(
                          right: entry.$1 == mix.length - 1 ? 20 : 8,
                        ),
                        child: BudgetMixPill(
                          key: _pillKeys[entry.$1],
                          index: entry.$1,
                          category: entry.$2.category,
                          type: 'Expense',
                          share:
                              totalSpent <= 0 ? 0 : entry.$2.spent / totalSpent,
                          active: _calledOutMixIndex == entry.$1,
                          shakeSerial: _shakeSerial,
                        ),
                      ),
                  ],
                ),
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
            color: BudgetMixPalette.staticColorForCategory(
              entry.$2.category,
              type: 'Expense',
            ),
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
            Dismissible(
              key: ValueKey('budget-row-${budgets[index].id}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) async {
                onDelete(budgets[index]);
                return false;
              },
              background: const SizedBox.shrink(),
              secondaryBackground: _SwipeDeleteBackground(
                key: const ValueKey('budget-swipe-action-delete'),
                label: 'Delete',
                color: colors.expense,
              ),
              child: ColoredBox(
                key: ValueKey(
                  'budget-swipe-foreground-${budgets[index].id}',
                ),
                color: colors.paper,
                child: _BudgetLedgerRow(
                  budget: budgets[index],
                  mixIndex: colorIndexByBudgetId[budgets[index].id] ?? index,
                  onEdit: () => onEdit(budgets[index]),
                ),
              ),
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
  });

  final Budget budget;
  final int mixIndex;
  final VoidCallback onEdit;

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
              color: BudgetMixPalette.colorForCategory(
                budget.category,
                context,
                type: 'Expense',
              ),
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
                        child: Text(
                          budget.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.ink,
                            fontWeight: FontWeight.w800,
                          ),
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
          ],
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

class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return SwipeActionBackground(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 10),
      children: [
        SwipeActionTile(
          icon: AppIconKey.delete,
          label: label,
          foregroundColor: color,
          backgroundColor: colors.expenseSoft,
          onTap: () {},
        ),
      ],
    );
  }
}
