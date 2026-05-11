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
          const Text('Nothing is shared until you preview and choose records.'),
          const SizedBox(height: 16),
          FeedCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: _includeTransactions,
                  onChanged: (value) =>
                      setState(() => _includeTransactions = value),
                  title: const Text('Transactions'),
                  subtitle: const Text('Expenses and contributions you pick.'),
                ),
                SwitchListTile(
                  value: _includeBudgets,
                  onChanged: (value) => setState(() => _includeBudgets = value),
                  title: const Text('Budgets'),
                  subtitle: const Text('Monthly caps for shared categories.'),
                ),
                SwitchListTile(
                  value: _includeRecurringSchedules,
                  onChanged: (value) =>
                      setState(() => _includeRecurringSchedules = value),
                  title: const Text('Recurring schedules'),
                  subtitle: const Text('Bills or contribution schedules.'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category filter (optional)',
                    prefixIcon: Icon(Icons.category_outlined),
                    helperText: 'Separate multiple categories with commas.',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preview', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        FeedCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.visibility_outlined),
              const SizedBox(width: 12),
              Expanded(child: Text(preview.warning)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (preview.items.isEmpty)
          const FeedCard(child: Text('No matching personal records found.'))
        else
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

    return FeedCard(
      child: CheckboxListTile(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(item.label),
        subtitle: Text('${item.category} · ${item.recordType}'),
        secondary: Text(
          amount,
          style: theme.textTheme.titleSmall,
        ),
      ),
    );
  }
}
