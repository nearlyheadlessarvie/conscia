import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_icons.dart';
import '../../core/constants/category_icons.dart';
import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../models/managed_category.dart';
import '../../providers/category_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/conscia_bottom_sheet.dart';
import '../../widgets/conscia_confirm_sheet.dart';
import '../../widgets/floating_label_text_field.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/conscia_app_bar.dart';
import '../../widgets/hero_shortcut_card.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/segmented_switch.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/swipe_action_tile.dart';

const _personalCategoryQuery = CategoryQuery(includeArchived: true);

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(
      managedCategoriesProvider(_personalCategoryQuery),
    );

    return HeroScreenScaffold(
      padding: EdgeInsets.zero,
      bleedBehindAppBar: true,
      appBar: ConsciaAppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Add category',
            onPressed: () => _showCategorySheet(context, ref),
            icon: AppIcons.icon(
              AppIconKey.add,
              color: Theme.of(context).appColors.deepNavy,
              size: 22,
            ),
          ),
        ],
      ),
      child: categoriesAsync.when(
        data: (categories) => _CategoryContent(
          categories: categories,
          onAdd: () => _showCategorySheet(context, ref),
          onArchive: (category) => _confirmArchive(context, ref, category),
        ),
        loading: () => Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.screenPadding,
            AppLayout.appBarClearHeroTop(context),
            AppLayout.screenPadding,
            0,
          ),
          child: const Column(
            children: [
              SkeletonCard(),
              SizedBox(height: 12),
              SkeletonCard(),
            ],
          ),
        ),
        error: (_, __) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppLayout.screenPadding,
            AppLayout.appBarClearHeroTop(context),
            AppLayout.screenPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unable to load categories',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(managedCategoriesProvider),
                icon: AppIcons.icon(
                  AppIconKey.refresh,
                  color: Theme.of(context).appColors.deepNavy,
                  size: 18,
                ),
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
    final subAsync = ref.read(subscriptionProvider);
    var isPremium = subAsync.valueOrNull?.isPremium;
    if (isPremium == null) {
      try {
        isPremium = (await ref.read(subscriptionProvider.future)).isPremium;
      } catch (_) {
        isPremium = false;
      }
      if (!context.mounted) return;
    }

    if (category == null && !isPremium) {
      await PremiumUpgradeDialog.show(
        context,
        feature: 'Custom categories are a Premium feature.',
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CategoryFormSheet(
        category: category,
        onSubmit: ({
          required String name,
          required String type,
          required String iconKey,
          required String colorKey,
        }) async {
          if (category == null) {
            await ref.read(categoryActionsProvider).create(
                  name: name,
                  type: type,
                  iconKey: iconKey,
                  colorKey: colorKey,
                );
            messenger.showSnackBar(
              const SnackBar(content: Text('Category created.')),
            );
          } else {
            await ref.read(categoryActionsProvider).update(
                  id: category.id,
                  name: name,
                  iconKey: iconKey,
                  colorKey: colorKey,
                );
            messenger.showSnackBar(
              const SnackBar(content: Text('Category updated.')),
            );
          }
          if (sheetContext.mounted) Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    ManagedCategory category,
  ) async {
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Archive ${category.name}?',
      message:
          'Existing transactions stay as-is, but this category will stop showing as an active option.',
      confirmLabel: 'Archive category',
    );

    if (!confirmed) return;
    try {
      await ref.read(categoryActionsProvider).archive(category.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category archived.')),
      );
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
    final customCount = active.where((category) => !category.isDefault).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoriesHero(
          expenseCount: expenses.length,
          incomeCount: income.length,
          customCount: customCount,
          onAdd: onAdd,
        ),
        const SizedBox(height: 28),
        _CategorySection(
          title: 'Expense',
          subtitle:
              'Spending labels used by transactions, budgets, and insights.',
          categories: expenses,
          emptyText: 'No expense categories yet.',
          onArchive: onArchive,
        ),
        const SizedBox(height: 28),
        _CategorySection(
          title: 'Income',
          subtitle:
              'Money-in labels for salary, gifts, refunds, and other sources.',
          categories: income,
          emptyText: 'No income categories yet.',
          onArchive: onArchive,
        ),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 28),
          _CategorySection(
            title: 'Archived',
            subtitle: 'Hidden from pickers, preserved for history.',
            categories: archived,
            emptyText: '',
            onArchive: onArchive,
            showArchiveAction: false,
          ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }
}

class _CategoriesHero extends StatelessWidget {
  const _CategoriesHero({
    required this.expenseCount,
    required this.incomeCount,
    required this.customCount,
    required this.onAdd,
  });

  final int expenseCount;
  final int incomeCount;
  final int customCount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.navySoft.withValues(alpha: 0.72),
            colors.paper,
            colors.amberSoft.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.screenPadding,
          AppLayout.bleedingHeroTop(context),
          AppLayout.screenPadding,
          AppLayout.heroBottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CATEGORY SYSTEM',
              style: textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Keep your money language tidy',
              style: textTheme.headlineSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Categories connect transactions, budgets, and insights without making you rename things twice.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                height: 1.28,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroStatPill(label: '$expenseCount expense'),
                _HeroStatPill(label: '$incomeCount income'),
                _HeroStatPill(label: '$customCount custom'),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: HeroShortcutCard(
                icon: AppIconKey.add,
                label: 'Add category',
                subtitle: 'Create a custom label',
                onPressed: onAdd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.deepNavy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.subtitle,
    required this.categories,
    required this.emptyText,
    required this.onArchive,
    this.showArchiveAction = true,
  });

  final String title;
  final String subtitle;
  final List<ManagedCategory> categories;
  final String emptyText;
  final ValueChanged<ManagedCategory> onArchive;
  final bool showArchiveAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppLayout.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: colors.mutedInk,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
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
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.border),
                bottom: BorderSide(color: colors.border),
              ),
            ),
            child: categories.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      emptyText,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.mutedInk,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < categories.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: AppLayout.listIconSize + 24,
                            color: colors.border,
                          ),
                        _CategoryRow(
                          category: categories[i],
                          onArchive: onArchive,
                          showArchiveAction: showArchiveAction,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
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
    final colors = theme.appColors;
    final status = category.isArchived
        ? 'Archived'
        : category.isDefault
            ? 'Default'
            : 'Custom';

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CategoryIcons.badge(
            category.name,
            type: category.type,
            iconKey: category.visualIconKey,
            colorKey: category.visualColorKey,
            size: AppLayout.listIconSize,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (!showArchiveAction || category.isDefault) return row;

    return Dismissible(
      key: ValueKey('category-row-${category.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onArchive(category);
        return false;
      },
      background: const SizedBox.shrink(),
      secondaryBackground: SwipeActionBackground(
        alignment: Alignment.centerRight,
        backgroundColor: colors.navySoft.withValues(alpha: 0.38),
        padding: const EdgeInsets.only(right: 0),
        children: [
          SwipeActionTile(
            key: const ValueKey('category-swipe-action-archive'),
            icon: AppIconKey.archive,
            label: 'Archive',
            foregroundColor: colors.deepNavy,
            backgroundColor: colors.navySoft.withValues(alpha: 0.38),
            onTap: () => onArchive(category),
          ),
        ],
      ),
      child: ColoredBox(color: colors.paper, child: row),
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
    required String iconKey,
    required String colorKey,
  }) onSubmit;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  static const _collapsedIconCount = 12;

  late final TextEditingController _nameController;
  late String _type;
  late String _iconKey;
  late String _colorKey;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _type = widget.category?.type ?? 'Expense';
    _iconKey = widget.category?.iconKey ??
        CategoryIcons.defaultIconKeyFor(widget.category?.name ?? '');
    _colorKey = widget.category?.colorKey ??
        CategoryIcons.defaultColorKeyFor(
          widget.category?.name ?? '',
          type: _type,
        );
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
    final colors = Theme.of(context).appColors;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConsciaSheetHandle(),
              const SizedBox(height: 18),
              ConsciaSheetHeader(
                title: isEditing ? 'Edit category' : 'New category',
                subtitle: isEditing
                    ? 'Update the label Conscia uses across records.'
                    : 'Create a custom label with an icon and color.',
              ),
              const SizedBox(height: 16),
              FloatingLabelTextField(
                controller: _nameController,
                label: 'Category name',
                autofocus: true,
                prefix: AppIcons.icon(
                  AppIconKey.label,
                  color: colors.deepNavy,
                  size: 18,
                ),
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  _clearError();
                  _refreshDefaultsIfNeeded();
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              SegmentedSwitch(
                items: const ['Expense', 'Income'],
                selectedItem: _type,
                selectedColor:
                    _type == 'Income' ? colors.income : colors.expense,
                enabled: !isEditing,
                normalized: false,
                onChanged: (value) => setState(() {
                  _errorText = null;
                  _type = value;
                  _colorKey = CategoryIcons.defaultColorKeyFor(
                    _nameController.text.trim(),
                    type: _type,
                  );
                }),
              ),
              const SizedBox(height: 18),
              _VisualSection(
                title: 'Icon',
                child: _IconChoiceRail(
                  options: _orderedIconOptions(),
                  colorKey: _colorKey,
                  selectedKey: _iconKey,
                  collapsedCount: _collapsedIconCount,
                  onSelected: (key) => setState(() {
                    _errorText = null;
                    _iconKey = key;
                  }),
                  onMore: _showIconPickerSheet,
                ),
              ),
              const SizedBox(height: 18),
              _VisualSection(
                title: 'Color',
                child: _ColorChoiceRail(
                  selectedKey: _colorKey,
                  onSelected: (key) => setState(() {
                    _errorText = null;
                    _colorKey = key;
                  }),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorText != null) ...[
                _CategoryFormError(message: _errorText!),
                const SizedBox(height: 14),
              ],
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
      ),
    );
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _errorText = null;
      _submitting = true;
    });
    try {
      await widget.onSubmit(
        name: name,
        type: _type,
        iconKey: _iconKey,
        colorKey: _colorKey,
      );
    } catch (e, s) {
      final error = AppError.from(e, stackTrace: s, log: false);
      if (!mounted) return;
      setState(() => _errorText = error.userMessage);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _clearError() {
    if (_errorText == null) return;
    setState(() => _errorText = null);
  }

  void _refreshDefaultsIfNeeded({bool forceColor = false}) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (widget.category?.iconKey == null && _iconKey == 'other') {
        _iconKey = CategoryIcons.defaultIconKeyFor(name);
      }
      if (forceColor || widget.category?.colorKey == null) {
        _colorKey = CategoryIcons.defaultColorKeyFor(name, type: _type);
      }
    });
  }

  List<CategoryIconOption> _orderedIconOptions() {
    final selected = CategoryIcons.iconOptions
        .where((option) => option.key == _iconKey)
        .toList(growable: false);
    return [
      ...selected,
      ...CategoryIcons.iconOptions.where((option) => option.key != _iconKey),
    ];
  }

  Future<void> _showIconPickerSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _IconPickerSheet(
        selectedKey: _iconKey,
        colorKey: _colorKey,
      ),
    );

    if (selected == null || !mounted) return;
    setState(() {
      _errorText = null;
      _iconKey = selected;
    });
  }
}

class _CategoryFormError extends StatelessWidget {
  const _CategoryFormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.expenseSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcons.icon(
              AppIconKey.error,
              size: 16,
              color: colors.expense,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.expense,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisualSection extends StatelessWidget {
  const _VisualSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _IconChoiceRail extends StatelessWidget {
  const _IconChoiceRail({
    required this.options,
    required this.colorKey,
    required this.selectedKey,
    required this.collapsedCount,
    required this.onSelected,
    required this.onMore,
  });

  final List<CategoryIconOption> options;
  final String colorKey;
  final String selectedKey;
  final int collapsedCount;
  final ValueChanged<String> onSelected;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final visible = options.take(collapsedCount).toList();
    final hasMore = options.length > collapsedCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in visible) ...[
            _IconOptionChip(
              option: option,
              colorKey: colorKey,
              selected: selectedKey == option.key,
              onTap: () => onSelected(option.key),
            ),
            const SizedBox(width: 8),
          ],
          if (hasMore)
            _MoreIconChip(
              colorKey: colorKey,
              onTap: onMore,
            ),
        ],
      ),
    );
  }
}

class _IconOptionChip extends StatelessWidget {
  const _IconOptionChip({
    required this.option,
    required this.colorKey,
    required this.selected,
    required this.onTap,
  });

  final CategoryIconOption option;
  final String colorKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryIcons.visualFor(
      option.label,
      iconKey: option.key,
      colorKey: colorKey,
    );
    return Tooltip(
      message: 'Icon: ${option.label}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color:
                selected ? visual.accent.withValues(alpha: 0.12) : visual.tint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              width: selected ? 1.5 : 1,
              color: selected
                  ? visual.accent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: CategoryIcons.trialFontPickerIcon(
              option.label,
              key: ValueKey('category-icon-chip-font-${option.key}'),
              iconKey: option.key,
              colorKey: colorKey,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreIconChip extends StatelessWidget {
  const _MoreIconChip({
    required this.colorKey,
    required this.onTap,
  });

  final String colorKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = CategoryIcons.visualFor(
      'Categories',
      iconKey: 'entertainment',
      colorKey: colorKey,
    );

    return Tooltip(
      message: 'Icon: More',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 94,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: visual.tint.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: visual.accent.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryIcons.trialFontPickerIcon(
                'Other',
                key: const ValueKey('category-icon-chip-font-other'),
                iconKey: 'other',
                colorKey: colorKey,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'More',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: visual.accent,
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

class _IconPickerSheet extends StatelessWidget {
  const _IconPickerSheet({
    required this.selectedKey,
    required this.colorKey,
  });

  final String selectedKey;
  final String colorKey;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ConsciaSheetHandle(),
              const SizedBox(height: 18),
              const ConsciaSheetHeader(
                title: 'Choose icon',
                subtitle: 'Pick the symbol that best matches this category.',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final option in CategoryIcons.iconOptions)
                    _IconOptionChip(
                      option: option,
                      colorKey: colorKey,
                      selected: selectedKey == option.key,
                      onTap: () => Navigator.of(context).pop(option.key),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorChoiceRail extends StatelessWidget {
  const _ColorChoiceRail({
    required this.selectedKey,
    required this.onSelected,
  });

  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in CategoryIcons.colorOptions) ...[
            _ColorOptionDot(
              option: option,
              selected: selectedKey == option.key,
              onTap: () => onSelected(option.key),
            ),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _ColorOptionDot extends StatelessWidget {
  const _ColorOptionDot({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CategoryColorOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Color: ${option.label}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: option.tint,
            border: Border.all(
              width: selected ? 2 : 1,
              color: selected
                  ? option.accent
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: option.accent,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(width: 14, height: 14),
            ),
          ),
        ),
      ),
    );
  }
}
