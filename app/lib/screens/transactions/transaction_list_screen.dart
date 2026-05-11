import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/transaction_providers.dart';
import '../../services/transaction_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/selection_chip_group.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/transaction_tile.dart';

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

    final categories = {
      if (selectedCategory != null) selectedCategory,
      ...state.transactions.map((t) => t.category),
    }.toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Add transaction',
            icon: const Icon(Icons.add),
            onPressed: () => context.push(AppRoutes.addTransaction),
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
        child: _buildBody(state, selectedCategory, categories),
      ),
    );
  }

  Widget _buildBody(
    TransactionListState state,
    String? selectedCategory,
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: ScreenSection(
            title: 'Filters',
            subtitle: 'Jump between your most recent spending categories.',
            compact: true,
            child: SelectionChipGroup(
              options: ['All', ...categories],
              value: selectedCategory ?? 'All',
              scrollable: true,
              onSelected: (value) {
                ref.read(categoryFilterProvider.notifier).state =
                    value == 'All' ? null : value;
              },
            ),
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
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
        itemCount: 8,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonListTile(),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
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
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        ..._buildGroupedSections(state.transactions),
        if (state.isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 28),
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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
            child: ScreenSection(
              title: _formatDateLabel(groups[key]!.first.date),
              compact: true,
              child: FeedCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var index = 0;
                        index < groups[key]!.length;
                        index++) ...[
                      TransactionTile(
                        id: groups[key]![index].id,
                        isIncome: groups[key]![index].type == 'income',
                        amount: groups[key]![index].amount,
                        currencyCode: groups[key]![index].currencyCode,
                        category: groups[key]![index].category,
                        counterparty: groups[key]![index].description,
                        date: groups[key]![index].date,
                        regretLevel: groups[key]![index].regretLevel,
                        isRecurring: groups[key]![index].isRecurring,
                      ),
                      if (index < groups[key]!.length - 1)
                        const Divider(indent: 72, height: 1),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
    ];
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
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
