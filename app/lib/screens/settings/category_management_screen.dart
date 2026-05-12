import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../core/errors/app_error.dart';
import '../../models/managed_category.dart';
import '../../providers/category_provider.dart';
import '../../widgets/feed_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/screen_section.dart';
import '../../widgets/skeleton_loader.dart';

const _personalCategoryQuery = CategoryQuery(includeArchived: true);

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(
      managedCategoriesProvider(_personalCategoryQuery),
    );

    return HeroScreenScaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Add category',
            onPressed: () => _showCategorySheet(context, ref),
            icon: Icon(AppIcons.add),
          ),
        ],
      ),
      child: categoriesAsync.when(
        data: (categories) => _CategoryContent(
          categories: categories,
          onAdd: () => _showCategorySheet(context, ref),
          onArchive: (category) => _confirmArchive(context, ref, category),
        ),
        loading: () => const Column(
          children: [
            SkeletonCard(),
            SizedBox(height: 12),
            SkeletonCard(),
          ],
        ),
        error: (_, __) => FeedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Unable to load categories'),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(managedCategoriesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCategorySheet(
    BuildContext context,
    WidgetRef ref, {
    ManagedCategory? category,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _CategoryFormSheet(
        category: category,
        onSubmit: ({
          required String name,
          required String type,
        }) async {
          try {
            if (category == null) {
              await ref.read(categoryActionsProvider).create(
                    name: name,
                    type: type,
                  );
            } else {
              await ref.read(categoryActionsProvider).update(
                    id: category.id,
                    name: name,
                  );
            }
            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
          } catch (e, s) {
            if (!sheetContext.mounted) return;
            final error = AppError.from(e, stackTrace: s);
            ScaffoldMessenger.of(sheetContext).showSnackBar(
              SnackBar(content: Text(error.userMessage)),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    ManagedCategory category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Archive ${category.name}?'),
        content: const Text(
          'Existing transactions stay as-is, but this category will stop '
          'showing as an active option.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ref.read(categoryActionsProvider).archive(category.id);
    } catch (e, s) {
      if (!context.mounted) return;
      final error = AppError.from(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }
}

class _CategoryContent extends StatelessWidget {
  const _CategoryContent({
    required this.categories,
    required this.onAdd,
    required this.onArchive,
  });

  final List<ManagedCategory> categories;
  final VoidCallback onAdd;
  final ValueChanged<ManagedCategory> onArchive;

  @override
  Widget build(BuildContext context) {
    final active = categories.where((category) => !category.isArchived);
    final expenses = active.where((category) => category.isExpense).toList();
    final income = active.where((category) => category.isIncome).toList();
    final archived = categories
        .where((category) => category.isArchived)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScreenSection(
          title: 'Manage categories',
          subtitle: 'Keep transaction, budget, and insight categories aligned.',
          child: FeedCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create custom labels for the way you actually spend.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAdd,
                    icon: Icon(AppIcons.add),
                    label: const Text('Add category'),
                  ),
                ),
              ],
            ),
          ),
        ),
        _CategorySection(
          title: 'Expense',
          categories: expenses,
          emptyText: 'No expense categories yet.',
          onArchive: onArchive,
        ),
        _CategorySection(
          title: 'Income',
          categories: income,
          emptyText: 'No income categories yet.',
          onArchive: onArchive,
        ),
        if (archived.isNotEmpty)
          _CategorySection(
            title: 'Archived',
            categories: archived,
            emptyText: '',
            onArchive: onArchive,
            showArchiveAction: false,
          ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.categories,
    required this.emptyText,
    required this.onArchive,
    this.showArchiveAction = true,
  });

  final String title;
  final List<ManagedCategory> categories;
  final String emptyText;
  final ValueChanged<ManagedCategory> onArchive;
  final bool showArchiveAction;

  @override
  Widget build(BuildContext context) {
    return ScreenSection(
      title: title,
      child: FeedCard(
        child: categories.isEmpty
            ? Text(
                emptyText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            : Column(
                children: [
                  for (var i = 0; i < categories.length; i++) ...[
                    if (i > 0) const Divider(height: 18),
                    _CategoryRow(
                      category: categories[i],
                      onArchive: onArchive,
                      showArchiveAction: showArchiveAction,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.onArchive,
    required this.showArchiveAction,
  });

  final ManagedCategory category;
  final ValueChanged<ManagedCategory> onArchive;
  final bool showArchiveAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CategoryIcons.badge(category.name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  category.type,
                  if (category.isDefault) 'Default',
                  if (category.isArchived) 'Archived',
                ].join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (showArchiveAction && !category.isDefault)
          IconButton(
            tooltip: 'Archive ${category.name}',
            onPressed: () => onArchive(category),
            icon: const Icon(Icons.archive_outlined),
          ),
      ],
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({
    required this.onSubmit,
    this.category,
  });

  final ManagedCategory? category;
  final Future<void> Function({
    required String name,
    required String type,
  }) onSubmit;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final TextEditingController _nameController;
  late String _type;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _type = widget.category?.type ?? 'Expense';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.category != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit category' : 'New category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Category name',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'Expense',
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: 'Income',
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_type},
              onSelectionChanged: isEditing
                  ? null
                  : (selection) => setState(() => _type = selection.first),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Text(isEditing ? 'Save changes' : 'Save category'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(name: name, type: _type);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
