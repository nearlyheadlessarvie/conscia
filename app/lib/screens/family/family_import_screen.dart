import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_error.dart';
import '../../models/family_import_preview.dart';
import '../../providers/family_space_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';

class FamilyImportScreen extends ConsumerStatefulWidget {
  const FamilyImportScreen({super.key});

  @override
  ConsumerState<FamilyImportScreen> createState() => _FamilyImportScreenState();
}

class _FamilyImportScreenState extends ConsumerState<FamilyImportScreen> {
  final _categoryController = TextEditingController();
  bool _includeTransactions = true;
  bool _includeBudgets = true;
  bool _includeRecurringSchedules = true;
  bool _isLoading = false;
  FamilyImportPreview? _preview;
  Set<String> _selectedIds = {};

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HeroScreenScaffold(
      appBar: AppBar(title: const Text('Import personal records')),
      bottom: _preview == null
          ? FilledButton(
              onPressed: _isLoading ? null : _previewRecords,
              child: Text(_isLoading ? 'Previewing...' : 'Preview records'),
            )
          : FilledButton(
              onPressed: _isLoading || _selectedIds.isEmpty ? null : _import,
              child: Text(_isLoading
                  ? 'Importing...'
                  : 'Import ${_selectedIds.length} selected'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FeedCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose what to share',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Nothing is shared until you import selected records.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Record types',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _ImportTypeOption(
                  icon: Icons.receipt_long_outlined,
                  title: 'Transactions',
                  subtitle: 'Expenses and contributions you choose below.',
                  selected: _includeTransactions,
                  onChanged: (value) =>
                      setState(() => _includeTransactions = value),
                ),
                _ImportTypeOption(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Budgets',
                  subtitle: 'Monthly caps for shared categories.',
                  selected: _includeBudgets,
                  onChanged: (value) => setState(() => _includeBudgets = value),
                ),
                _ImportTypeOption(
                  icon: Icons.repeat_outlined,
                  title: 'Recurring schedules',
                  subtitle: 'Bills or contribution schedules.',
                  selected: _includeRecurringSchedules,
                  onChanged: (value) =>
                      setState(() => _includeRecurringSchedules = value),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Categories to include',
                    hintText: 'Dining, Groceries',
                    prefixIcon: Icon(Icons.category_outlined),
                    helperText:
                        'Optional. Leave blank to preview all selected record types.',
                  ),
                ),
              ],
            ),
          ),
          if (_preview case final preview?) ...[
            const SizedBox(height: 16),
            FamilyImportPreviewList(
              preview: preview,
              selectedIds: _selectedIds,
              onSelectionChanged: (ids) => setState(() => _selectedIds = ids),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _previewRecords() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final preview = await ref.read(familySpaceActionsProvider).previewImport(
            includeTransactions: _includeTransactions,
            includeBudgets: _includeBudgets,
            includeRecurringSchedules: _includeRecurringSchedules,
            categories: _categories,
          );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _selectedIds = preview.items.map((item) => item.selectionKey).toSet();
      });
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _import() async {
    final preview = _preview;
    if (preview == null) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final selections = preview.items
          .where((item) => _selectedIds.contains(item.selectionKey))
          .map((item) => FamilyImportSelection(
                recordType: item.recordType,
                recordId: item.recordId,
              ))
          .toList();
      final imported =
          await ref.read(familySpaceActionsProvider).importRecords(selections);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Imported $imported records to Family.')),
      );
      Navigator.of(context).maybePop();
    } catch (e, s) {
      if (!mounted) return;
      final error = AppError.from(e, stackTrace: s);
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<String> get _categories => _categoryController.text
      .split(',')
      .map((category) => category.trim())
      .where((category) => category.isNotEmpty)
      .toList();
}

class FamilyImportPreviewList extends StatelessWidget {
  const FamilyImportPreviewList({
    super.key,
    required this.preview,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  final FamilyImportPreview preview;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = preview.items.length;
    final selectedCount = selectedIds.length;
    final allSelected = totalCount > 0 && selectedCount == totalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Review before sharing',
                  style: theme.textTheme.titleMedium),
            ),
            if (totalCount > 0)
              TextButton(
                onPressed: () {
                  onSelectionChanged(
                    allSelected
                        ? <String>{}
                        : preview.items
                            .map((item) => item.selectionKey)
                            .toSet(),
                  );
                },
                child: Text(allSelected ? 'Clear all' : 'Select all'),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          totalCount == 0
              ? 'No records to import yet.'
              : '$selectedCount of $totalCount selected',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        if (preview.items.isEmpty)
          const FeedCard(
            child: Text('No personal records match those choices.'),
          )
        else ...[
          _ImportVisibilityNote(message: preview.warning),
          const SizedBox(height: 10),
        ],
        if (preview.items.isNotEmpty)
          ...preview.items.map((item) => _ImportItemTile(
                item: item,
                selected: selectedIds.contains(item.selectionKey),
                onChanged: (selected) {
                  final next = {...selectedIds};
                  if (selected) {
                    next.add(item.selectionKey);
                  } else {
                    next.remove(item.selectionKey);
                  }
                  onSelectionChanged(next);
                },
              )),
      ],
    );
  }
}

class _ImportTypeOption extends StatelessWidget {
  const _ImportTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => onChanged(!selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: selected
                  ? colors.primaryContainer.withValues(alpha: 0.68)
                  : colors.surfaceContainerHighest,
              child: Icon(
                icon,
                size: 18,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: selected,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ImportVisibilityNote extends StatelessWidget {
  const _ImportVisibilityNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportItemTile extends StatelessWidget {
  const _ImportItemTile({
    required this.item,
    required this.selected,
    required this.onChanged,
  });

  final FamilyImportItem item;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount =
        '${item.currencyCode} ${NumberFormat('#,##0.00').format(item.amount)}';
    final colors = theme.colorScheme;

    return FeedCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      onTap: () => onChanged(!selected),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primaryContainer.withValues(alpha: 0.45),
            child: Icon(
              _recordTypeIcon(item.recordType),
              size: 18,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  '${item.category} · ${_recordTypeLabel(item.recordType)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: theme.textTheme.labelLarge),
              Checkbox(
                value: selected,
                onChanged: (value) => onChanged(value ?? false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _recordTypeIcon(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'budget':
        return Icons.account_balance_wallet_outlined;
      case 'recurring':
      case 'recurringschedule':
      case 'recurring_schedule':
        return Icons.repeat_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  static String _recordTypeLabel(String recordType) {
    switch (recordType.toLowerCase()) {
      case 'budget':
        return 'Budget';
      case 'recurring':
      case 'recurringschedule':
      case 'recurring_schedule':
        return 'Recurring';
      default:
        return 'Transaction';
    }
  }
}
