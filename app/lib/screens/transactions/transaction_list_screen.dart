import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../providers/budget_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_provider.dart';
import '../../services/budget_service.dart';
import '../../services/transaction_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/conscia_confirm_sheet.dart';
import '../../widgets/conscia_glyph.dart';
import '../../widgets/editorial_sticky_header.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/selection_chip_group.dart';
import '../../widgets/skeleton_loader.dart';
import '../../../widgets/form_label.dart';
import '../budgets/widgets/budget_form_sheet.dart';
import 'transaction_form_screen.dart';
import 'widgets/editorial_transaction_row.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  static const _filterRailHeight = 56.0;

  final _scrollController = ScrollController();
  final _filterAnchorKey = GlobalKey();
  double _scrollOffset = 0;
  double? _filterOverlayTop;
  bool _scrollSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    _syncScrollOffset();
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(filteredTransactionListProvider.notifier).loadMore();
    }
  }

  void _syncScrollOffset() {
    final nextOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    if ((nextOffset - _scrollOffset).abs() >= 1) {
      setState(() => _scrollOffset = nextOffset);
    }
  }

  void _scheduleFrameSync(double filterPinnedTop) {
    if (_scrollSyncScheduled) return;
    _scrollSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSyncScheduled = false;
      if (!mounted) return;
      _syncScrollOffset();
      _syncFilterOverlayTop(filterPinnedTop);
    });
  }

  Future<void> _confirmDeleteTransaction(Transaction transaction) async {
    final userPrefs = ref.read(userPreferencesProvider);
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Delete this transaction?',
      message: 'This can\'t be undone.',
      confirmLabel: 'Delete transaction',
      preview: EditorialTransactionRow(
        data: EditorialTransactionRowData.fromTransaction(
          transaction,
          displayCategory: _displayCategory(transaction),
        ),
        locale: userPrefs.locale,
        onTap: () {},
      ),
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(transactionServiceProvider).delete(transaction.id);
      ref.invalidate(transactionListProvider);
      ref.invalidate(filteredTransactionListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }

  void _syncFilterOverlayTop(double pinnedTop) {
    final renderObject = _filterAnchorKey.currentContext?.findRenderObject();
    final anchorTop = renderObject is RenderBox && renderObject.attached
        ? renderObject.localToGlobal(Offset.zero).dy
        : null;
    final measuredTop =
        anchorTop == null || anchorTop < pinnedTop ? pinnedTop : anchorTop;

    if (_filterOverlayTop == null ||
        (measuredTop - _filterOverlayTop!).abs() >= 0.5) {
      setState(() => _filterOverlayTop = measuredTop);
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(filteredTransactionListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(filteredTransactionListProvider);
    final budgetState = ref.watch(budgetListProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final userPreferences = ref.watch(userPreferencesProvider);
    final categories = {
      if (selectedCategory != null) selectedCategory,
      ...state.transactions.map(_displayCategory),
    }.toList()
      ..sort();

    final effectiveScrollOffset =
        _scrollController.hasClients ? _scrollController.offset : _scrollOffset;
    final stickyProgress = ((effectiveScrollOffset - 5) / 10).clamp(0.0, 1.0);
    final filterPinnedTop = AppLayout.transactionFilterPinnedTop(context);
    final isFilterPinned = _filterOverlayTop != null &&
        _filterOverlayTop! <= filterPinnedTop + 0.5;
    final showSkeletonPills = state.isLoading && state.transactions.isEmpty;

    _scheduleFrameSync(filterPinnedTop);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).appColors.pageTop,
              Theme.of(context).appColors.pageBottom,
            ],
          ),
        ),
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                key: const PageStorageKey('transactions-shell-scroll'),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: _buildSlivers(
                  state,
                  budgetState.budgets,
                  selectedCategory,
                  userPreferences,
                ),
              ),
            ),
            if (_filterOverlayTop != null)
              Positioned(
                top: _filterOverlayTop!,
                left: 0,
                right: 0,
                child: _TransactionFilterRailOverlay(
                  pinned: isFilterPinned,
                  scrollController: _scrollController,
                  child: _TransactionFilterRailContent(
                    selectedCategory: selectedCategory,
                    categories: categories,
                    showSkeletonPills: showSkeletonPills,
                    onSelected: (value) {
                      ref.read(categoryFilterProvider.notifier).state =
                          value == 'All' ? null : value;
                    },
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EditorialStickyHeader(
                title: 'Transactions',
                progress: stickyProgress,
                topPadding: MediaQuery.paddingOf(context).top,
                trailing: IconButton(
                  tooltip: 'Add transaction',
                  visualDensity: VisualDensity.compact,
                  icon: AppIcons.icon(
                    AppIconKey.add,
                    color: Theme.of(context).appColors.deepNavy,
                    size: 20,
                  ),
                  onPressed: () => TransactionFormSheet.show(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSlivers(
    TransactionListState state,
    List<Budget> budgets,
    String? selectedCategory,
    ({String currency, String locale}) userPreferences,
  ) {
    if (state.error != null && state.transactions.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _TransactionsEditorialHero(
            transactions: state.transactions,
            selectedCategory: selectedCategory,
            topPadding: MediaQuery.paddingOf(context).top,
            currencyCode: userPreferences.currency,
            locale: userPreferences.locale,
          ),
        ),
        _buildFilterRailSpacer(),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: FeedCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcons.icon(
                      AppIconKey.error,
                      color: Theme.of(context).colorScheme.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _onRefresh,
                      icon: AppIcons.icon(
                        AppIconKey.refresh,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 18,
                      ),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverToBoxAdapter(
        child: _TransactionsEditorialHero(
          transactions: state.transactions,
          selectedCategory: selectedCategory,
          topPadding: MediaQuery.paddingOf(context).top,
          currencyCode: userPreferences.currency,
          locale: userPreferences.locale,
        ),
      ),
      _buildFilterRailSpacer(),
      ..._buildListSlivers(state, budgets, userPreferences.locale),
    ];
  }

  Widget _buildFilterRailSpacer() {
    return SliverToBoxAdapter(
      child: SizedBox(
        key: _filterAnchorKey,
        height: _filterRailHeight,
      ),
    );
  }

  List<Widget> _buildListSlivers(
    TransactionListState state,
    List<Budget> budgets,
    String locale,
  ) {
    if (state.isLoading && state.transactions.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList.builder(
            itemCount: 8,
            itemBuilder: (_, __) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonListTile(),
            ),
          ),
        ),
      ];
    }

    if (state.transactions.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: EmptyState(
              icon: Icons.circle_outlined,
              illustration: _TransactionEmptyStateIcon(),
              title: 'No transactions yet',
              subtitle: 'Tap + to add your first',
            ),
          ),
        ),
      ];
    }

    return [
      ..._buildGroupedSections(state.transactions, budgets, locale),
      if (state.isLoading)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
    ];
  }

  List<Widget> _buildGroupedSections(
    List<Transaction> transactions,
    List<Budget> budgets,
    String locale,
  ) {
    final groups = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final key =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
      (groups[key] ??= []).add(tx);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final key in sortedKeys)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormLabel(label: _formatDateLabel(groups[key]!.first.date)),
                const SizedBox(height: 10),
                EditorialTransactionRowsGroup(
                  surface: false,
                  horizontalPadding: 0,
                  children: [
                    for (var index = 0; index < groups[key]!.length; index++)
                      _SwipeableTransactionActionRow(
                        key: ValueKey(
                          'transaction-row-${groups[key]![index].id}',
                        ),
                        canReflect: groups[key]![index].type != 'income',
                        canAddBudget:
                            _canAddBudget(groups[key]![index], budgets),
                        onEdit: () => TransactionFormSheet.show(
                          context,
                          transactionId: groups[key]![index].id,
                        ),
                        onReflect: () => context.push(
                          AppRoutes.transactionDetail(
                            groups[key]![index].id,
                            autoReflect: true,
                          ),
                        ),
                        onAddBudget: () => BudgetFormSheet.show(
                          context,
                          initialCategory:
                              _displayCategory(groups[key]![index]),
                        ),
                        onDelete: () =>
                            _confirmDeleteTransaction(groups[key]![index]),
                        child: EditorialTransactionRow(
                          data: EditorialTransactionRowData.fromTransaction(
                            groups[key]![index],
                            displayCategory:
                                _displayCategory(groups[key]![index]),
                          ),
                          locale: locale,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  String _displayCategory(Transaction tx) {
    if (tx.isFamily && tx.category.startsWith('Family ')) {
      return tx.category.substring('Family '.length);
    }
    return tx.category;
  }

  bool _canAddBudget(Transaction tx, List<Budget> budgets) {
    if (tx.type == 'income') return false;
    final normalizedCategory = _displayCategory(tx).trim().toLowerCase();
    return !budgets.any(
      (budget) => budget.category.trim().toLowerCase() == normalizedCategory,
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) {
      return 'Today · ${DateFormat.MMMd().format(date)}';
    }
    if (diff == 1) {
      return 'Yesterday · ${DateFormat.MMMd().format(date)}';
    }
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]} · ${months[date.month - 1]} ${date.day}';
  }
}

class _SwipeableTransactionActionRow extends StatefulWidget {
  const _SwipeableTransactionActionRow({
    super.key,
    required this.child,
    required this.canReflect,
    required this.canAddBudget,
    required this.onEdit,
    required this.onReflect,
    required this.onAddBudget,
    required this.onDelete,
  });

  final Widget child;
  final bool canReflect;
  final bool canAddBudget;
  final VoidCallback onEdit;
  final VoidCallback onReflect;
  final VoidCallback onAddBudget;
  final VoidCallback onDelete;

  @override
  State<_SwipeableTransactionActionRow> createState() =>
      _SwipeableTransactionActionRowState();
}

class _SwipeableTransactionActionRowState
    extends State<_SwipeableTransactionActionRow>
    with SingleTickerProviderStateMixin {
  static const _actionExtent = 0.22;
  static const _deleteExtent = 0.24;
  static const _commitThreshold = 0.58;

  late final SlidableController _controller;
  bool _handlingCommittedSwipe = false;

  int get _actionCount =>
      1 + (widget.canReflect ? 1 : 0) + (widget.canAddBudget ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _controller = SlidableController(this)
      ..endGesture.addListener(_handleCommittedSwipe);
  }

  @override
  void dispose() {
    _controller.endGesture.removeListener(_handleCommittedSwipe);
    _controller.dispose();
    super.dispose();
  }

  double get _startExtent =>
      (_actionCount * _actionExtent).clamp(_actionExtent, 0.72).toDouble();

  void _handleCommittedSwipe() {
    if (_handlingCommittedSwipe) return;

    final ratio = _controller.ratio;
    if (ratio <= -_commitThreshold) {
      _runCommittedAction(widget.onDelete);
      return;
    }

    if (_actionCount == 1 && ratio >= _commitThreshold) {
      _runCommittedAction(widget.onEdit);
    }
  }

  void _runCommittedAction(VoidCallback action) {
    _handlingCommittedSwipe = true;
    _controller.close(duration: Duration.zero);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handlingCommittedSwipe = false;
      action();
    });
  }

  String get _rowId {
    final rawKey = widget.key;
    if (rawKey is ValueKey<String>) {
      return rawKey.value.replaceFirst('transaction-row-', '');
    }
    return 'row';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final radius = BorderRadius.circular(18);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.ink.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Slidable(
          key: widget.key,
          controller: _controller,
          groupTag: 'transactions',
          closeOnScroll: true,
          startActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: _startExtent,
            dismissible: _actionCount == 1
                ? _TransactionSlidablePreview(
                    label: 'Edit',
                    icon: AppIconKey.edit,
                    foregroundColor: colors.deepNavy,
                    backgroundColor: colors.navySoft.withValues(alpha: 0.72),
                    alignment: Alignment.centerLeft,
                  )
                : null,
            children: [
              _TransactionSlidableAction(
                label: 'Edit',
                icon: AppIconKey.edit,
                foregroundColor: colors.deepNavy,
                backgroundColor: colors.navySoft.withValues(alpha: 0.72),
                onPressed: widget.onEdit,
              ),
              if (widget.canReflect)
                _TransactionSlidableAction(
                  label: 'Reflect',
                  icon: AppIconKey.ai,
                  foregroundColor: colors.deepNavy,
                  backgroundColor: colors.navySoft.withValues(alpha: 0.72),
                  onPressed: widget.onReflect,
                ),
              if (widget.canAddBudget)
                _TransactionSlidableAction(
                  label: 'Add budget',
                  icon: AppIconKey.flag,
                  foregroundColor: colors.deepNavy,
                  backgroundColor: colors.amberSoft,
                  onPressed: widget.onAddBudget,
                ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: _deleteExtent,
            dismissible: _TransactionSlidablePreview(
              label: 'Delete',
              icon: AppIconKey.delete,
              foregroundColor: colors.expense,
              backgroundColor: colors.expenseSoft,
              alignment: Alignment.centerRight,
            ),
            children: [
              _TransactionSlidableAction(
                label: 'Delete',
                icon: AppIconKey.delete,
                foregroundColor: colors.expense,
                backgroundColor: colors.expenseSoft,
                onPressed: widget.onDelete,
              ),
            ],
          ),
          child: DecoratedBox(
            key: ValueKey('transaction-swipe-foreground-$_rowId'),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: radius,
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _TransactionSlidablePreview extends StatelessWidget {
  const _TransactionSlidablePreview({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.alignment,
  });

  final String label;
  final AppIconKey icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return ColoredBox(
      color: backgroundColor.withValues(alpha: 0.38),
      child: Align(
        alignment: alignment,
        child: SizedBox(
          width: 92,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcons.icon(
                icon,
                color: foregroundColor,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.ink,
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

class _TransactionEmptyStateIcon extends StatelessWidget {
  const _TransactionEmptyStateIcon();

  @override
  Widget build(BuildContext context) {
    return AppIcons.icon(
      AppIconKey.receipt,
      color: Theme.of(context).colorScheme.outlineVariant,
      size: 64,
      strokeWidth: 1.7,
    );
  }
}

class _TransactionSlidableAction extends StatelessWidget {
  const _TransactionSlidableAction({
    required this.label,
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final AppIconKey icon;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return CustomSlidableAction(
      key: ValueKey('swipe-action-tile-$label'),
      backgroundColor: backgroundColor.withValues(alpha: 0.38),
      padding: EdgeInsets.zero,
      onPressed: (_) => onPressed(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcons.icon(
            icon,
            color: foregroundColor,
            size: 20,
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionFilterRailOverlay extends StatelessWidget {
  const _TransactionFilterRailOverlay({
    required this.pinned,
    required this.scrollController,
    required this.child,
  });

  final bool pinned;
  final ScrollController scrollController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final railHeight =
        pinned ? 43.0 : _TransactionListScreenState._filterRailHeight;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        final delta = details.primaryDelta;
        if (delta == null || !scrollController.hasClients) return;

        final position = scrollController.position;
        final nextOffset = (scrollController.offset - delta)
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble();
        scrollController.jumpTo(nextOffset);
      },
      child: SizedBox(
        key: const ValueKey('transaction-filter-rail-overlay'),
        height: railHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.paper.withValues(alpha: pinned ? 0.96 : 0.0),
            border: Border(
              bottom: BorderSide(
                color: pinned
                    ? colors.border.withValues(alpha: 0.72)
                    : Colors.transparent,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TransactionFilterRailContent extends StatelessWidget {
  const _TransactionFilterRailContent({
    required this.selectedCategory,
    required this.categories,
    required this.showSkeletonPills,
    required this.onSelected,
  });

  final String? selectedCategory;
  final List<String> categories;
  final bool showSkeletonPills;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (!showSkeletonPills) {
      return SelectionChipGroup(
        options: ['All', ...categories.take(4)],
        value: selectedCategory ?? 'All',
        scrollable: true,
        avatarBuilder: (option, _) => option == 'All'
            ? null
            : CategoryIcons.rawIcon(option, size: 13, type: 'Expense'),
        onSelected: onSelected,
      );
    }

    final visibleOption = selectedCategory ?? 'All';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SelectionChipButton(
            label: visibleOption,
            selected: true,
            avatar: visibleOption == 'All'
                ? null
                : CategoryIcons.rawIcon(
                    visibleOption,
                    size: 13,
                    type: 'Expense',
                  ),
            onTap: () => onSelected(visibleOption),
          ),
          const SizedBox(width: 10),
          for (var index = 0; index < 4; index++) ...[
            SkeletonLoader(
              key: ValueKey('transaction-filter-skeleton-pill-$index'),
              width: switch (index) {
                0 => 70,
                1 => 84,
                2 => 76,
                _ => 66,
              },
              height: 30,
              borderRadius: 999,
            ),
            if (index < 3) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _TransactionsEditorialHero extends StatelessWidget {
  const _TransactionsEditorialHero({
    required this.transactions,
    required this.selectedCategory,
    required this.topPadding,
    required this.currencyCode,
    required this.locale,
  });

  final List<Transaction> transactions;
  final String? selectedCategory;
  final double topPadding;
  final String currencyCode;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final visibleTransactions = selectedCategory == null
        ? transactions
        : transactions
            .where((tx) => _displayCategory(tx) == selectedCategory)
            .toList(growable: false);
    final monthTransactions = _monthTransactions(visibleTransactions);
    final basis =
        monthTransactions.isNotEmpty ? monthTransactions : visibleTransactions;
    final totalSpent = basis
        .where((tx) => tx.type != 'income')
        .fold(0.0, (sum, tx) => sum + _amountInUserCurrency(tx));
    final topCategory = _topExpenseCategory(basis);
    final repeatCount = basis
        .where((tx) => tx.type != 'income')
        .map(_displayCategory)
        .toSet()
        .length;
    final regretCount = basis
        .where((tx) => tx.regretLevel != null && tx.type != 'income')
        .length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppLayout.screenPadding,
        topPadding + AppLayout.transactionListHeroTopGap,
        AppLayout.screenPadding,
        26,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.navySoft,
            colors.paper,
            colors.amberSoft.withValues(alpha: 0.78),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPENDING TRAIL',
            style: textTheme.labelSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(
              totalSpent,
              currencyCode: currencyCode,
              locale: locale,
            ),
            style: textTheme.displaySmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _summaryCopy(topCategory, basis.length),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  glyph: ConsciaGlyph(
                    kind: ConsciaGlyphKind.trail,
                    size: 14,
                    color: colors.deepNavy,
                  ),
                  label: '${basis.length} moments',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  glyph: ConsciaGlyph(
                    kind: ConsciaGlyphKind.signal,
                    size: 14,
                    color: colors.deepNavy,
                  ),
                  label: '$repeatCount patterns',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  glyph: ConsciaGlyph(
                    kind: ConsciaGlyphKind.reflect,
                    size: 14,
                    color: colors.deepNavy,
                  ),
                  label: '$regretCount reflected',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Transaction> _monthTransactions(List<Transaction> input) {
    final now = DateTime.now();
    return input
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList(growable: false);
  }

  String? _topExpenseCategory(List<Transaction> input) {
    final totals = <String, double>{};
    for (final tx in input.where((tx) => tx.type != 'income')) {
      final category = _displayCategory(tx);
      totals[category] = (totals[category] ?? 0) + tx.amount.abs();
    }
    if (totals.isEmpty) return selectedCategory;
    return totals.entries
        .reduce((best, next) => next.value > best.value ? next : best)
        .key;
  }

  String _summaryCopy(String? topCategory, int count) {
    if (count == 0) {
      return 'Your spending moments will collect here, ready for patterns and reflection.';
    }
    if (selectedCategory != null) {
      return '$selectedCategory is in focus. Notice the timing, repeats, and small cues below.';
    }
    if (topCategory == null) {
      return 'Income is landing here. Spending patterns will appear as your history grows.';
    }
    return '$topCategory is showing up most lately. Follow the trail below for repeat moments and reflection cues.';
  }

  double _amountInUserCurrency(Transaction tx) {
    final amount = tx.amount.abs();
    if (tx.currencyCode == currencyCode) return amount;
    final rate = tx.exchangeRateToBase;
    if (rate == null || rate <= 0) return amount;
    return amount * rate;
  }

  String _displayCategory(Transaction tx) {
    if (tx.isFamily && tx.category.startsWith('Family ')) {
      return tx.category.substring('Family '.length);
    }
    return tx.category;
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.glyph, required this.label});

  final Widget glyph;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          glyph,
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.deepNavy,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
