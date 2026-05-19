import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/alert_provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/usage_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/ai_service.dart';
import '../../services/transaction_service.dart';
import '../../core/constants/category_icons.dart';
import '../budgets/widgets/budget_form_sheet.dart';
import '../../widgets/ai_guidance_chat.dart';
import '../../widgets/ai_guidance_loading_sheet.dart';
import '../../widgets/conscia_bottom_sheet.dart';
import '../../widgets/conscia_confirm_sheet.dart';
import '../../widgets/editorial_sticky_header.dart';
import '../../widgets/feeling_choice_button.dart';
import '../../widgets/form_label.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/skeleton_loader.dart';
import 'transaction_form_screen.dart';
import 'widgets/editorial_transaction_row.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;
  final bool autoReflect;

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.autoReflect = false,
  });

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  static const _contentTopGap = 65.0;

  final _scrollController = ScrollController();
  int? _regretLevel;
  bool _regretLevelInitialized = false;
  bool _deleting = false;
  Transaction? _editedTransactionOverride;
  bool _autoReflectHandled = false;
  double _scrollOffset = 0;
  bool _scrollSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncScrollOffset);
    ref.read(budgetListProvider);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncScrollOffset)
      ..dispose();
    super.dispose();
  }

  void _syncScrollOffset() {
    final nextOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    if ((nextOffset - _scrollOffset).abs() >= 1) {
      setState(() => _scrollOffset = nextOffset);
    }
  }

  void _scheduleScrollOffsetSync() {
    if (_scrollSyncScheduled) return;
    _scrollSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSyncScheduled = false;
      if (!mounted) return;
      _syncScrollOffset();
    });
  }

  Color _amountColor(ColorScheme colors, bool isIncome) {
    if (!isIncome) {
      return colors.brightness == Brightness.light
          ? const Color(0xFFE53935)
          : const Color(0xFFEF9A9A);
    }
    return colors.brightness == Brightness.light
        ? const Color(0xFF4CAF50)
        : const Color(0xFF81C784);
  }

  Future<void> _confirmDelete(Transaction? transaction) async {
    final userPrefs = ref.read(userPreferencesProvider);
    final transactionForContext = transaction ?? _editedTransactionOverride;
    final confirmed = await ConsciaConfirmSheet.show(
      context,
      title: 'Delete this transaction?',
      message: "This can't be undone.",
      confirmLabel: 'Delete transaction',
      preview: transactionForContext == null
          ? null
          : EditorialTransactionRow(
              data: EditorialTransactionRowData.fromTransaction(
                transactionForContext,
              ),
              locale: userPrefs.locale,
              onTap: () {},
            ),
    );

    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      final service = ref.read(transactionServiceProvider);
      await service.delete(widget.transactionId);
      final didUpdateBudget = transaction != null &&
          ref
              .read(budgetListProvider.notifier)
              .applyOptimisticTransactionDelete(transaction);
      if (didUpdateBudget && ref.read(budgetReconciliationEnabledProvider)) {
        ref.read(budgetListProvider.notifier).scheduleRefreshInBackground();
      }
      if (!mounted) return;
      ref.invalidate(transactionListProvider);
      ref.invalidate(filteredTransactionListProvider);
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    } catch (e, s) {
      if (!mounted) return;
      setState(() => _deleting = false);
      final error = AppError.from(e, stackTrace: s);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.userMessage)),
      );
    }
  }

  Future<void> _updateRegret(int level) async {
    setState(() => _regretLevel = level);
    try {
      final service = ref.read(transactionServiceProvider);
      await service.updateRegret(widget.transactionId, level);
      ref.invalidate(transactionDetailProvider(widget.transactionId));
      ref.invalidate(transactionListProvider);
      ref.invalidate(filteredTransactionListProvider);
    } catch (_) {
      // Optimistic update — ignore errors silently
    }
  }

  void _askAiReflection({
    bool dismissFollowUpAlert = false,
    Transaction? transaction,
  }) async {
    final reflectionTransaction = transaction ??
        _editedTransactionOverride ??
        ref.read(transactionDetailProvider(widget.transactionId)).valueOrNull;

    if (dismissFollowUpAlert) {
      final alerts = ref.read(activeAlertsProvider);
      final matchingFollowUp = alerts.where(
        (alert) =>
            alert.type == 'ReflectionFollowUp' &&
            alert.transactionId == widget.transactionId,
      );
      for (final alert in matchingFollowUp) {
        ref.read(dismissedAlertIdsProvider.notifier).dismiss(alert.id);
      }
    }

    final service = ref.read(transactionServiceProvider);
    try {
      await service.updateRegret(widget.transactionId, _regretLevel ?? 1);
      ref.invalidate(transactionDetailProvider(widget.transactionId));
      ref.invalidate(transactionListProvider);
      ref.invalidate(filteredTransactionListProvider);
    } catch (_) {
      // Best-effort
    }

    if (!mounted) return;
    _showReflectionSheet(reflectionTransaction);
  }

  void _showReflectionSheet(Transaction? transaction) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => _ReflectionSheet(
          scrollController: scrollController,
          transactionId: widget.transactionId,
          transaction: transaction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(transactionDetailProvider(widget.transactionId));
    final currentTransaction =
        _editedTransactionOverride ?? detailAsync.valueOrNull;
    final topPadding = MediaQuery.paddingOf(context).top;
    final effectiveScrollOffset =
        _scrollController.hasClients ? _scrollController.offset : _scrollOffset;
    final stickyProgress = ((effectiveScrollOffset - 5) / 10).clamp(0.0, 1.0);
    _scheduleScrollOffsetSync();

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
            Positioned.fill(
              child: detailAsync.when(
                loading: () => SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _TransactionDetailSkeleton(
                    topPadding:
                        topPadding + AppLayout.transactionDetailHeroTopGap,
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      32,
                      topPadding + _contentTopGap,
                      32,
                      32,
                    ),
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
                          AppError.from(error, stackTrace: stackTrace)
                              .userMessage,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => ref.invalidate(
                              transactionDetailProvider(widget.transactionId)),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (tx) => _buildContent(
                  _editedTransactionOverride ?? tx,
                  topPadding,
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EditorialStickyHeader(
                title: 'Transaction',
                progress: stickyProgress,
                topPadding: topPadding,
                trailing: IconButton(
                  tooltip: 'Transaction actions',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_horiz_rounded),
                  onPressed: currentTransaction == null
                      ? null
                      : () => _showTransactionActions(currentTransaction),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditScreen() async {
    final updatedTransaction = await TransactionFormSheet.show(
      context,
      transactionId: widget.transactionId,
    );

    if (!mounted || updatedTransaction == null) return;

    setState(() {
      _editedTransactionOverride = updatedTransaction;
      _regretLevel = updatedTransaction.regretLevel;
      _regretLevelInitialized = updatedTransaction.regretLevel != null;
    });
  }

  Future<void> _showTransactionActions(Transaction tx) async {
    final action = await showModalBottomSheet<_TransactionAction>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => _TransactionActionsSheet(
        canReflect: tx.type != 'income',
        canAddBudget: _shouldShowAddBudget(tx),
        canDelete: !_deleting,
      ),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case _TransactionAction.reflect:
        _askAiReflection(transaction: tx);
      case _TransactionAction.addBudget:
        _openBudgetForm(_displayCategory(tx));
      case _TransactionAction.edit:
        await _openEditScreen();
      case _TransactionAction.delete:
        await _confirmDelete(tx);
    }
  }

  bool _shouldShowAddBudget(Transaction tx) {
    if (tx.type == 'income') return false;
    final budgetState = ref.read(budgetListProvider);
    if (budgetState.isLoading) return false;
    final normalizedCategory = _displayCategory(tx).trim().toLowerCase();
    return !budgetState.budgets.any(
      (budget) => budget.category.trim().toLowerCase() == normalizedCategory,
    );
  }

  Widget _buildContent(Transaction tx, double topPadding) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appColors = theme.appColors;
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = ref.watch(authProvider).userId;
    final isIncome = tx.type == 'income';
    final prefix = isIncome ? '+' : '-';
    final displayCounterparty =
        tx.description.isNotEmpty ? tx.description : 'Unknown';
    final displayCategory = _displayCategory(tx);

    if (widget.autoReflect && !_autoReflectHandled) {
      _autoReflectHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _askAiReflection(
          dismissFollowUpAlert: true,
          transaction: tx,
        );
      });
    }

    if (!_regretLevelInitialized) {
      _regretLevel = tx.regretLevel;
      _regretLevelInitialized = true;
    }

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TransactionDetailHero(
            category: tx.category,
            counterparty: displayCounterparty,
            snapshotLabel: isIncome ? 'INCOME SNAPSHOT' : 'PURCHASE SNAPSHOT',
            amountText:
                '$prefix${CurrencyFormatter.format(tx.amount.abs(), currencyCode: tx.currencyCode)}',
            amountColor: _amountColor(colors, isIncome),
            subtitle: '${isIncome ? "Income" : "Expense"} · $displayCategory',
            isIncome: isIncome,
            topPadding: topPadding + AppLayout.transactionDetailHeroTopGap,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const FormLabel(label: 'DETAILS'),
                const SizedBox(height: 10),
                _DetailRowsGroup(
                  children: [
                    _DetailRow(
                      label: 'Category',
                      value: displayCategory,
                      leading: CategoryIcons.badge(
                        displayCategory,
                        size: 30,
                        type: isIncome ? 'Income' : 'Expense',
                      ),
                    ),
                    _DetailRow(
                      label: 'Date',
                      value: DateFormat.yMMMd().add_jm().format(tx.date),
                      leading: Icon(
                        Icons.calendar_today_outlined,
                        color: appColors.deepNavy,
                        size: 20,
                      ),
                    ),
                    _DetailRow(
                      label: 'Type',
                      value: isIncome ? 'Income' : 'Expense',
                      leading: Icon(
                        isIncome
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isIncome ? appColors.income : appColors.expense,
                        size: 20,
                      ),
                    ),
                    if (tx.isRecurring || tx.isFamily)
                      _DetailRow(
                        label: 'Shared context',
                        value: tx.isRecurring && tx.isFamily
                            ? 'Recurring family transaction'
                            : tx.isFamily
                                ? 'Family transaction'
                                : 'Recurring transaction',
                        leading: Icon(
                          tx.isFamily
                              ? Icons.people_rounded
                              : Icons.repeat_rounded,
                          color: tx.isFamily
                              ? appColors.family
                              : appColors.deepNavy,
                          size: 20,
                        ),
                        trailing: _shouldShowSharerAvatar(tx, currentUserId)
                            ? CircleAvatar(
                                key:
                                    const ValueKey('transaction-sharer-avatar'),
                                radius: 13,
                                backgroundColor: colors.tertiaryContainer,
                                child: Text(
                                  _sharerInitials(tx),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.onTertiaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (!isIncome) _buildRegretSection(textTheme),
                if (_deleting) ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openBudgetForm(String category) {
    BudgetFormSheet.show(context, initialCategory: category);
  }

  Widget _buildRegretSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FormLabel(label: 'HOW DID THIS FEEL?'),
        const SizedBox(height: 4),
        Text(
          'Mark the feeling so future insights understand the pattern.',
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).appColors.mutedInk,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 14),
        if (_regretLevel != null) _buildRegretChip() else _buildRegretPicker(),
      ],
    );
  }

  String _displayCategory(Transaction tx) {
    if (tx.isFamily && tx.category.startsWith('Family ')) {
      return tx.category.substring('Family '.length);
    }
    return tx.category;
  }

  bool _shouldShowSharerAvatar(Transaction tx, String? currentUserId) =>
      tx.sharedByUserId != null &&
      tx.sharedByUserId!.isNotEmpty &&
      tx.sharedByUserId != currentUserId;

  String _sharerInitials(Transaction tx) {
    final explicit = tx.sharedByInitials?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit.length <= 2
          ? explicit.toUpperCase()
          : explicit.substring(0, 2).toUpperCase();
    }

    final compactId = tx.sharedByUserId?.replaceAll('-', '') ?? '';
    if (compactId.length >= 2) return compactId.substring(0, 2).toUpperCase();
    return '?';
  }

  Widget _buildRegretChip() {
    final level = _regretLevel!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _feelingButtonForLevel(
          level,
          size: FeelingChoiceButtonSize.compact,
          onPressed: () => setState(() => _regretLevel = null),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Change feeling',
          onPressed: () => setState(() => _regretLevel = null),
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildRegretPicker() {
    return Row(
      children: [
        Expanded(
          child: FeelingChoiceButton.worthIt(
            size: FeelingChoiceButtonSize.large,
            onPressed: () => _updateRegret(0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FeelingChoiceButton.notSure(
            size: FeelingChoiceButtonSize.large,
            onPressed: () => _updateRegret(1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FeelingChoiceButton.regret(
            size: FeelingChoiceButtonSize.large,
            onPressed: () => _updateRegret(2),
          ),
        ),
      ],
    );
  }

  Widget _feelingButtonForLevel(
    int level, {
    required FeelingChoiceButtonSize size,
    required VoidCallback onPressed,
  }) {
    if (level == 0) {
      return FeelingChoiceButton.worthIt(size: size, onPressed: onPressed);
    }
    if (level == 1) {
      return FeelingChoiceButton.notSure(size: size, onPressed: onPressed);
    }
    return FeelingChoiceButton.regret(size: size, onPressed: onPressed);
  }
}

class _TransactionDetailHero extends StatelessWidget {
  const _TransactionDetailHero({
    required this.category,
    required this.counterparty,
    required this.snapshotLabel,
    required this.amountText,
    required this.amountColor,
    required this.subtitle,
    required this.isIncome,
    required this.topPadding,
  });

  final String category;
  final String counterparty;
  final String snapshotLabel;
  final String amountText;
  final Color amountColor;
  final String subtitle;
  final bool isIncome;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    return DecoratedBox(
      key: const ValueKey('transaction-detail-hero'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.navySoft,
            colors.paper,
            colors.amberSoft.withValues(alpha: 0.74),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, topPadding, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryIcons.badge(
                  category,
                  size: 44,
                  type: isIncome ? 'Income' : 'Expense',
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    snapshotLabel,
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.deepNavy,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              counterparty,
              style: textTheme.titleLarge?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amountText,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: amountColor,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.mutedInk,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionActionsSheet extends StatelessWidget {
  const _TransactionActionsSheet({
    required this.canReflect,
    required this.canAddBudget,
    required this.canDelete,
  });

  final bool canReflect;
  final bool canAddBudget;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = canReflect
        ? 'Edit this record or ask Conscia to read the pattern.'
        : 'Edit or remove this income record from your history.';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ConsciaSheetHandle(),
            const SizedBox(height: 18),
            ConsciaSheetHeader(
              title: 'Transaction actions',
              subtitle: subtitle,
            ),
            const SizedBox(height: 18),
            if (canReflect)
              _TransactionActionRow(
                icon: Icons.auto_awesome_rounded,
                title: 'Reflect with Conscia',
                subtitle: 'Read the pattern behind this purchase.',
                onTap: () =>
                    Navigator.of(context).pop(_TransactionAction.reflect),
              ),
            if (canAddBudget)
              _TransactionActionRow(
                icon: Icons.flag_rounded,
                title: 'Add budget',
                subtitle: 'Create a monthly cap for this category.',
                onTap: () =>
                    Navigator.of(context).pop(_TransactionAction.addBudget),
              ),
            _TransactionActionRow(
              icon: Icons.edit_rounded,
              title: 'Edit transaction',
              subtitle: 'Adjust the amount, category, date, or details.',
              onTap: () => Navigator.of(context).pop(_TransactionAction.edit),
            ),
            if (canDelete)
              _TransactionActionRow(
                icon: Icons.delete_outline_rounded,
                title: 'Delete transaction',
                subtitle: 'Remove this record from your history.',
                destructive: true,
                onTap: () =>
                    Navigator.of(context).pop(_TransactionAction.delete),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionActionRow extends StatelessWidget {
  const _TransactionActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final accent = destructive ? colors.expense : colors.deepNavy;
    final background = destructive ? colors.expenseSoft : colors.navySoft;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: AppLayout.listIconSize,
              height: AppLayout.listIconSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedInk,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.softInk),
          ],
        ),
      ),
    );
  }
}

enum _TransactionAction { reflect, addBudget, edit, delete }

class _TransactionDetailSkeleton extends StatelessWidget {
  const _TransactionDetailSkeleton({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          key: const ValueKey('transaction-detail-hero-skeleton'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.navySoft,
                colors.paper,
                colors.amberSoft.withValues(alpha: 0.74),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            border: Border.all(color: colors.border),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, topPadding, 18, 20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonLoader(
                      width: 44,
                      height: 44,
                      borderRadius: 16,
                    ),
                    SizedBox(width: 14),
                    SkeletonLoader(width: 132, height: 12),
                  ],
                ),
                SizedBox(height: 22),
                SkeletonLoader(width: 150, height: 20),
                SizedBox(height: 10),
                SkeletonLoader(width: 190, height: 34),
                SizedBox(height: 12),
                SkeletonLoader(width: 128, height: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: 64, height: 12),
              SizedBox(height: 12),
              _SkeletonDetailRow(),
              _SkeletonDivider(),
              _SkeletonDetailRow(),
              _SkeletonDivider(),
              _SkeletonDetailRow(),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLoader(width: 132, height: 12),
              SizedBox(height: 8),
              SkeletonLoader(width: 260, height: 14),
              SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                      child: SkeletonLoader(height: 40, borderRadius: 999)),
                  SizedBox(width: 8),
                  Expanded(
                      child: SkeletonLoader(height: 40, borderRadius: 999)),
                  SizedBox(width: 8),
                  Expanded(
                      child: SkeletonLoader(height: 40, borderRadius: 999)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonDetailRow extends StatelessWidget {
  const _SkeletonDetailRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SkeletonLoader(width: 30, height: 30, borderRadius: 10),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: 72, height: 10),
                SizedBox(height: 6),
                SkeletonLoader(width: 128, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonDivider extends StatelessWidget {
  const _SkeletonDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).appColors.border,
    );
  }
}

class _DetailRowsGroup extends StatelessWidget {
  const _DetailRowsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final separatedChildren = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      separatedChildren.add(children[index]);
      if (index < children.length - 1) {
        separatedChildren.add(
          Divider(
            height: 1,
            thickness: 1,
            color: colors.border,
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: separatedChildren,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.leading,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(width: 30, height: 30, child: Center(child: leading)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.mutedInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _ReflectionSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final String transactionId;
  final Transaction? transaction;

  const _ReflectionSheet({
    required this.scrollController,
    required this.transactionId,
    this.transaction,
  });

  @override
  ConsumerState<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends ConsumerState<_ReflectionSheet> {
  AIResponse? _response;
  bool _loading = true;
  String? _error;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _fetchReflection();
  }

  Future<void> _fetchReflection() async {
    _cancelToken?.cancel('Starting a new reflection request.');
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.reflection(
        transactionId: widget.transactionId,
        cancelToken: cancelToken,
      );
      if (!mounted) return;
      ref.read(monthlyUsageProvider.notifier).recordReflection();
      setState(() {
        _response = response;
        _loading = false;
      });
    } on DioException catch (e, s) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      if (e.response?.statusCode == 403) {
        Navigator.of(context).pop();
        PremiumUpgradeDialog.show(
          context,
          feature: e.response?.data?['error'] as String? ??
              'You\'ve reached the free tier limit for reflections.',
        );
        return;
      }
      setState(() {
        _loading = false;
        _error = AppError.from(e, stackTrace: s).userMessage;
      });
    } catch (e, s) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppError.from(e, stackTrace: s).userMessage;
      });
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Reflection sheet closed.');
    super.dispose();
  }

  String _reflectionPrompt(Transaction? transaction) {
    if (transaction == null) {
      return 'Help me reflect on this purchase.';
    }

    final amount = CurrencyFormatter.format(
      transaction.amount.abs(),
      currencyCode: transaction.currencyCode,
    );
    final target = transaction.description.trim().isNotEmpty
        ? transaction.description.trim()
        : transaction.category.trim().isNotEmpty
            ? transaction.category.trim()
            : 'this purchase';
    return 'Help me reflect on $amount at $target.';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final profile = ref.watch(currentUserProvider).valueOrNull;

    if (_loading) {
      return AiGuidanceLoadingSheet(
        keyPrefix: 'reflection',
        scrollController: widget.scrollController,
        title: 'Reflection',
        message: 'Reflection is making sense of the moment...',
        cloudSize: 196,
      );
    }

    return Column(
      children: [
        const SizedBox(height: 8),
        const AiGuidanceSheetHandle(),
        Expanded(
          child: _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: colors.error),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _fetchReflection();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  children: [
                    AiGuidanceChatMessage(
                      keyPrefix: 'reflection',
                      speaker: AiGuidanceSpeaker.user,
                      message: _reflectionPrompt(widget.transaction),
                      userProfile: profile,
                    ),
                    const SizedBox(height: 12),
                    AiGuidanceChatMessage(
                      keyPrefix: 'reflection',
                      speaker: AiGuidanceSpeaker.devil,
                      message: _response!.impulse,
                    ),
                    const SizedBox(height: 12),
                    AiGuidanceChatMessage(
                      keyPrefix: 'reflection',
                      speaker: AiGuidanceSpeaker.angel,
                      message: _response!.reason,
                    ),
                    const SizedBox(height: 12),
                    AiGuidanceChatMessage(
                      keyPrefix: 'reflection',
                      speaker: AiGuidanceSpeaker.conscia,
                      message: _response!.neutral,
                      badgeLabel: 'Reflection',
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
