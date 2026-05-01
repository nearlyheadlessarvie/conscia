import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/empty_state.dart';
import 'widgets/date_section_header.dart';
import 'widgets/transaction_tile.dart';

// ── Mock data for UI development ────────────────────────────────────────

final _mockTransactions = [
  _MockTx('1', false, 45.20, 'USD', 'Groceries', 'Walmart',
      DateTime.now(), 1),
  _MockTx('2', false, 6.50, 'USD', 'Coffee', 'Starbucks',
      DateTime.now(), null),
  _MockTx('3', true, 3500.00, 'USD', 'Salary', 'Acme Corp',
      DateTime.now().subtract(const Duration(days: 1)), null),
  _MockTx('4', false, 12.99, 'USD', 'Entertainment', 'Netflix',
      DateTime.now().subtract(const Duration(days: 1)), 2),
  _MockTx('5', false, 89.00, 'USD', 'Shopping', 'Amazon',
      DateTime.now().subtract(const Duration(days: 2)), 3),
  _MockTx('6', false, 32.50, 'USD', 'Dining', 'Chipotle',
      DateTime.now().subtract(const Duration(days: 3)), 1),
  _MockTx('7', false, 150.00, 'USD', 'Bills', 'Electric Co',
      DateTime.now().subtract(const Duration(days: 4)), null),
  _MockTx('8', true, 250.00, 'USD', 'Freelance', 'Client X',
      DateTime.now().subtract(const Duration(days: 5)), null),
];

class _MockTx {
  final String id, currencyCode, category;
  final String? merchant;
  final bool isIncome;
  final double amount;
  final DateTime date;
  final int? regretLevel;

  _MockTx(this.id, this.isIncome, this.amount, this.currencyCode,
      this.category, this.merchant, this.date, this.regretLevel);
}

// ── Screen ──────────────────────────────────────────────────────────────

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final _scrollController = ScrollController();
  String? _selectedCategory;
  bool _loadingMore = false;

  List<String> get _categories {
    final cats = _mockTransactions.map((t) => t.category).toSet().toList();
    cats.sort();
    return cats;
  }

  List<_MockTx> get _filtered {
    if (_selectedCategory == null) return _mockTransactions;
    return _mockTransactions
        .where((t) => t.category == _selectedCategory)
        .toList();
  }

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
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore) {
      // TODO: wire to transactionListProvider.loadMore()
    }
  }

  Future<void> _onRefresh() async {
    // TODO: wire to transactionListProvider.refresh()
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: filtered.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildFilterBar(),
                  ..._buildGroupedList(filtered),
                  if (_loadingMore)
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
            ),
    );
  }

  Widget _buildEmpty() {
    if (_selectedCategory != null) {
      return Column(
        children: [
          SizedBox(
            height: 52,
            child: _buildFilterChips(),
          ),
          Expanded(
            child: EmptyState(
              icon: Icons.filter_list_off,
              title: 'No $_selectedCategory transactions',
              subtitle: 'Try a different filter',
            ),
          ),
        ],
      );
    }
    return const EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No transactions yet',
      subtitle: 'Tap + to add your first',
    );
  }

  SliverPersistentHeader _buildFilterBar() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _FilterBarDelegate(child: _buildFilterChips()),
    );
  }

  Widget _buildFilterChips() {
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
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
            ),
          ),
          for (final cat in _categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(cat),
                selected: _selectedCategory == cat,
                onSelected: (_) =>
                    setState(() => _selectedCategory = cat),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedList(List<_MockTx> transactions) {
    final groups = <String, List<_MockTx>>{};
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
                isIncome: tx.isIncome,
                amount: tx.amount,
                currencyCode: tx.currencyCode,
                category: tx.category,
                merchant: tx.merchant,
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
  bool shouldRebuild(covariant _FilterBarDelegate oldDelegate) => true;
}
