import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/category_icons.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/user_provider.dart';
import '../../services/transaction_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/editorial_sticky_header.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/selection_chip_group.dart';
import '../../widgets/skeleton_loader.dart';
import '../../../widgets/form_label.dart';
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
    final filterPinnedTop = MediaQuery.paddingOf(context).top + 62;
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
                  icon: const Icon(Icons.add_rounded),
                  onPressed: () => context.push(AppRoutes.addTransaction),
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
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
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
                      icon: const Icon(Icons.refresh),
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
      ..._buildListSlivers(state, userPreferences.locale),
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
    String locale,
  ) {
    if (state.isLoading && state.transactions.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
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
            padding: EdgeInsets.fromLTRB(20, 0, 20, 112),
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              subtitle: 'Tap + to add your first',
            ),
          ),
        ),
      ];
    }

    return [
      ..._buildGroupedSections(state.transactions, locale),
      if (state.isLoading)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 112),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      const SliverPadding(padding: EdgeInsets.only(bottom: 112)),
    ];
  }

  List<Widget> _buildGroupedSections(
    List<Transaction> transactions,
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
                FormLabel(
                    label: _formatDateLabel(groups[key]!.first.date)
                        .toUpperCase()),
                const SizedBox(height: 10),
                EditorialTransactionRowsGroup(
                  children: [
                    for (var index = 0; index < groups[key]!.length; index++)
                      EditorialTransactionRow(
                        data: EditorialTransactionRowData.fromTransaction(
                          groups[key]![index],
                          displayCategory:
                              _displayCategory(groups[key]![index]),
                        ),
                        locale: locale,
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

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) {
      return 'Today, ${DateFormat.MMMd().format(date)}';
    }
    if (diff == 1) {
      return 'Yesterday, ${DateFormat.MMMd().format(date)}';
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
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
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
        avatarBuilder: (option, _) =>
            option == 'All' ? null : CategoryIcons.rawIcon(option, size: 13),
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
                : CategoryIcons.rawIcon(visibleOption, size: 13),
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
      padding: EdgeInsets.fromLTRB(20, topPadding + 75, 20, 26),
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
            'MONEY TRAIL',
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
            style: GoogleFonts.inter(
              textStyle: textTheme.displaySmall,
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
                  icon: Icons.receipt_long_rounded,
                  label: '${basis.length} entries',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.category_rounded,
                  label: '$repeatCount categories',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  icon: Icons.psychology_rounded,
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
      return 'Your transactions will turn into a clearer money story once history appears here.';
    }
    if (selectedCategory != null) {
      return '$selectedCategory is in focus. Use this trail to spot timing, repeats, and reflection cues.';
    }
    if (topCategory == null) {
      return 'Income is landing here. Expense patterns will appear as your spending history grows.';
    }
    return '$topCategory is carrying the strongest activity lately. Scan the trail below for repeats and reflection cues.';
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
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
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
          Icon(icon, size: 14, color: colors.deepNavy),
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
