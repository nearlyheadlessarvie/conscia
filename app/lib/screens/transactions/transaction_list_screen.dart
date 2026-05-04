import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/transaction_providers.dart';
import '../../services/transaction_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import 'widgets/date_section_header.dart';
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
      ref.read(transactionListProvider.notifier).loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await ref.read(transactionListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionListProvider);
    final selectedCategory = ref.watch(categoryFilterProvider);

    final categories = state.transactions
        .map((t) => t.category)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: _buildBody(state, selectedCategory, categories),
    );
  }

  Widget _buildBody(
    TransactionListState state,
    String? selectedCategory,
    List<String> categories,
  ) {
    if (state.isLoading && state.transactions.isEmpty) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => const SkeletonListTile(),
      );
    }

    if (state.error != null && state.transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions yet',
        subtitle: 'Tap + to add your first',
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildFilterBar(selectedCategory, categories),
          ..._buildGroupedList(state.transactions),
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  SliverPersistentHeader _buildFilterBar(
    String? selectedCategory,
    List<String> categories,
  ) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterBarDelegate(
        child: _buildFilterChips(selectedCategory, categories),
      ),
    );
  }

  Widget _buildFilterChips(String? selectedCategory, List<String> categories) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedCategory == null,
              onSelected: (_) =>
                  ref.read(categoryFilterProvider.notifier).state = null,
            ),
          ),
          for (final cat in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat),
                selected: selectedCategory == cat,
                onSelected: (_) =>
                    ref.read(categoryFilterProvider.notifier).state = cat,
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedList(List<Transaction> transactions) {
    final groups = <String, List<Transaction>>{};
    for (final tx in transactions) {
      final key =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
      (groups[key] ??= []).add(tx);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final slivers = <Widget>[];

    for (final key in sortedKeys) {
      final txs = groups[key]!;
      final date = txs.first.date;

      slivers.add(SliverToBoxAdapter(
        child: DateSectionHeader(date: date),
      ));

      slivers.add(SliverList.builder(
        itemCount: txs.length,
        itemBuilder: (context, index) {
          final tx = txs[index];
          return Column(
            children: [
              TransactionTile(
                id: tx.id,
                isIncome: tx.type == 'income',
                amount: tx.amount,
                currencyCode: tx.currencyCode,
                category: tx.category,
                merchant: tx.description,
                date: tx.date,
                regretLevel: tx.regretLevel,
              ),
              if (index < txs.length - 1)
                const Divider(indent: 72, height: 1),
            ],
          );
        },
      ));
    }

    return slivers;
  }
}

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _FilterBarDelegate({required this.child});

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) =>
      oldDelegate.child != child;
}
