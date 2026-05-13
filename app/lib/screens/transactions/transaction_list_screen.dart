import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/category_icons.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_space_provider.dart';
import '../../providers/transaction_providers.dart';
import '../../services/transaction_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/scope_pill_switch.dart';
import '../../widgets/selection_chip_group.dart';
import '../../widgets/skeleton_loader.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final _scrollController = ScrollController();

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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(filteredTransactionListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(filteredTransactionListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(filteredTransactionListProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);
    final selectedScope = ref.watch(transactionScopeFilterProvider);
    final hasFamilySpace = ref.watch(familySpaceProvider).valueOrNull != null;

    final categories = {
      if (selectedCategory != null) selectedCategory,
      ...state.transactions.map(_displayCategory),
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              tooltip: 'Add transaction',
              icon: const Icon(Icons.add),
              onPressed: () => context.push(AppRoutes.addTransaction),
            ),
          ),
        ],
      ),
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
        child: _buildBody(
          state,
          selectedCategory,
          selectedScope,
          hasFamilySpace,
          categories,
        ),
      ),
    );
  }

  Widget _buildBody(
    TransactionListState state,
    String? selectedCategory,
    String selectedScope,
    bool hasFamilySpace,
    List<String> categories,
  ) {
    if (state.error != null && state.transactions.isEmpty) {
      return Center(
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
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            children: [
              ScopePillSwitch(
                value: selectedScope,
                familyEnabled: hasFamilySpace,
                onChanged: (scope) {
                  ref.read(transactionScopeFilterProvider.notifier).state =
                      scope;
                },
              ),
              const SizedBox(height: 12),
              SelectionChipGroup(
                options: ['All', ...categories.take(4)],
                value: selectedCategory ?? 'All',
                scrollable: true,
                avatarBuilder: (option, _) => option == 'All'
                    ? null
                    : CategoryIcons.rawIcon(option, size: 13),
                onSelected: (value) {
                  ref.read(categoryFilterProvider.notifier).state =
                      value == 'All' ? null : value;
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: _buildScrollableList(state),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollableList(TransactionListState state) {
    if (state.isLoading && state.transactions.isEmpty) {
      return ListView.builder(
        key: const PageStorageKey('transactions-shell-scroll'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
        itemCount: 8,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonListTile(),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return ListView(
        key: const PageStorageKey('transactions-shell-scroll'),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
        children: const [
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            subtitle: 'Tap + to add your first',
          ),
        ],
      );
    }

    return CustomScrollView(
      key: const PageStorageKey('transactions-shell-scroll'),
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        ..._buildGroupedSections(state.transactions),
        if (state.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 112),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildGroupedSections(List<Transaction> transactions) {
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
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateLabel(groups[key]!.first.date).toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).appColors.softInk,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: [
                    for (var index = 0;
                        index < groups[key]!.length;
                        index++) ...[
                      _EditorialTransactionRow(
                        transaction: groups[key]![index],
                        displayCategory: _displayCategory(groups[key]![index]),
                        currentUserId: ref.watch(authProvider).userId,
                      ),
                      if (index < groups[key]!.length - 1)
                        const Divider(height: 4),
                    ],
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

class _EditorialTransactionRow extends StatelessWidget {
  const _EditorialTransactionRow({
    required this.transaction,
    required this.displayCategory,
    required this.currentUserId,
  });

  final Transaction transaction;
  final String displayCategory;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final colors = Theme.of(context).appColors;
    final amountColor = isIncome ? colors.income : colors.expense;
    final amountPrefix = isIncome ? '+' : '-';
    final counterparty = transaction.description.trim().isEmpty
        ? 'Unknown'
        : transaction.description;

    final rowStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return InkWell(
      onTap: () => context.push('/transactions/${transaction.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CategoryIcons.badge(displayCategory, size: 28),
            const SizedBox(width: 12),
            // Left column: merchant + category name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    counterparty,
                    style: rowStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    displayCategory,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedInk,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right column: amount + icon-only tags (family → recurring → regret)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${CurrencyFormatter.format(transaction.amount.abs(), currencyCode: transaction.currencyCode)}',
                  style: rowStyle?.copyWith(color: amountColor),
                ),
                if (transaction.isFamily ||
                    transaction.isRecurring ||
                    transaction.regretLevel != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (transaction.isFamily)
                        _IconTag(
                          icon: Icons.people_rounded,
                          color: colors.family,
                        ),
                      if (transaction.isRecurring)
                        _IconTag(
                          icon: Icons.repeat_rounded,
                          color: colors.deepNavy,
                        ),
                      if (transaction.regretLevel != null)
                        _IconTag(
                          icon: _regretIcon(transaction.regretLevel!),
                          color: _regretColor(
                            transaction.regretLevel!,
                            colors,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _regretColor(int level, AppColors colors) {
    if (level == 0) return colors.income;
    if (level == 1) return colors.amber;
    return colors.expense;
  }

  IconData _regretIcon(int level) {
    if (level == 0) return Icons.check_circle_rounded;
    if (level == 1) return Icons.help_rounded;
    return Icons.sentiment_dissatisfied_rounded;
  }
}

class _IconTag extends StatelessWidget {
  const _IconTag({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }
}
