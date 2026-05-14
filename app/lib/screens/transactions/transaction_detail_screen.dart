import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/errors/app_error.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/alert_provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_providers.dart';
import '../../providers/transaction_providers.dart';
import '../../providers/usage_provider.dart';
import '../../services/ai_service.dart';
import '../../services/transaction_service.dart';
import '../../core/constants/category_icons.dart';
import '../../screens/assistant/widgets/ai_message_bubble.dart';
import '../../screens/dashboard/widgets/in_app_alert_banner.dart';
import '../../widgets/conscience_mark.dart';
import '../../widgets/family_badge.dart';
import '../../widgets/form_label.dart';
import '../../widgets/grouped_list_card.dart';
import '../../widgets/hero_screen_scaffold.dart';
import '../../widgets/premium_upgrade_dialog.dart';
import '../../widgets/recurring_badge.dart';
import '../../widgets/skeleton_loader.dart';

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
  int? _regretLevel;
  bool _regretLevelInitialized = false;
  bool _loadingReflection = false;
  bool _deleting = false;
  Transaction? _editedTransactionOverride;
  bool _autoReflectHandled = false;

  @override
  void initState() {
    super.initState();
    ref.read(budgetListProvider);
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this transaction?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

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

  void _askAiReflection({bool dismissFollowUpAlert = false}) async {
    setState(() => _loadingReflection = true);

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
    setState(() => _loadingReflection = false);
    _showReflectionSheet();
  }

  void _showReflectionSheet() {
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
    final alerts = ref.watch(activeAlertsProvider);

    return HeroScreenScaffold(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      scrollable: false,
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openEditScreen();
              } else if (value == 'delete') {
                _confirmDelete(currentTransaction);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      child: detailAsync.when(
        loading: () => ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: const [
            SkeletonLoader(height: 40, width: 200),
            SizedBox(height: 24),
            SkeletonCard(),
            SizedBox(height: 16),
            SkeletonCard(),
            SizedBox(height: 16),
            SkeletonCard(),
          ],
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  AppError.from(error, stackTrace: stackTrace).userMessage,
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
        data: (tx) => _buildContent(_editedTransactionOverride ?? tx, alerts),
      ),
    );
  }

  Future<void> _openEditScreen() async {
    final updatedTransaction = await context.push<Transaction>(
      '/transactions/${widget.transactionId}/edit',
    );

    if (!mounted || updatedTransaction == null) return;

    setState(() {
      _editedTransactionOverride = updatedTransaction;
      _regretLevel = updatedTransaction.regretLevel;
      _regretLevelInitialized = updatedTransaction.regretLevel != null;
    });
  }

  bool _isCurrentTransactionRoute(String? route) {
    if (route == null || route.isEmpty) return false;

    final uri = Uri.tryParse(route);
    final path = uri?.path ?? route.split('?').first;
    final normalizedPath =
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;

    return normalizedPath == '/transactions/${widget.transactionId}';
  }

  bool _shouldHideContextualAlertAction(AppAlert alert) {
    if (alert.type == 'ReflectionFollowUp') return false;

    final isViewTransactionAction =
        alert.actionLabel?.trim().toLowerCase() == 'view transaction';
    return isViewTransactionAction &&
        (alert.transactionId == widget.transactionId ||
            _isCurrentTransactionRoute(alert.actionRoute));
  }

  Widget _buildContent(Transaction tx, List<AppAlert> alerts) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appColors = theme.appColors;
    final textTheme = Theme.of(context).textTheme;
    final currentUserId = ref.watch(authProvider).userId;
    final isIncome = tx.type == 'income';
    final prefix = isIncome ? '+' : '-';
    final displayCounterparty =
        tx.description.isNotEmpty ? tx.description : 'Unknown';
    AppAlert? contextualAlert;
    for (final alert in alerts) {
      final matchesTransaction = alert.transactionId == tx.id;
      final matchesCategory = alert.category != null &&
          alert.category!.toLowerCase() == tx.category.toLowerCase();
      final matchesCounterparty = alert.counterparty != null &&
          alert.counterparty!.toLowerCase() ==
              displayCounterparty.toLowerCase();
      if (matchesTransaction || matchesCategory || matchesCounterparty) {
        contextualAlert = alert;
        break;
      }
    }

    if (widget.autoReflect && !_autoReflectHandled) {
      _autoReflectHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _askAiReflection(dismissFollowUpAlert: true);
      });
    }

    if (!_regretLevelInitialized) {
      _regretLevel = tx.regretLevel;
      _regretLevelInitialized = true;
    }

    if (widget.autoReflect &&
        contextualAlert?.type == 'ReflectionFollowUp' &&
        contextualAlert?.transactionId == widget.transactionId) {
      contextualAlert = null;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          _TransactionDetailHero(
            category: tx.category,
            counterparty: displayCounterparty,
            amountText:
                '$prefix${CurrencyFormatter.format(tx.amount.abs(), currencyCode: tx.currencyCode)}',
            amountColor: _amountColor(colors, isIncome),
            subtitle:
                '${isIncome ? "Income" : "Expense"} · ${_displayCategory(tx)}',
          ),
          const SizedBox(height: 20),
          const FormLabel(label: 'DETAILS'),
          const SizedBox(height: 10),
          GroupedListCard(
            children: [
              _DetailRow(
                label: 'Category',
                value: _displayCategory(tx),
                leading: CategoryIcons.badge(_displayCategory(tx), size: 30),
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
                    tx.isFamily ? Icons.people_rounded : Icons.repeat_rounded,
                    color: tx.isFamily ? appColors.family : appColors.deepNavy,
                    size: 20,
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (tx.isRecurring) const RecurringBadge(),
                      if (tx.isFamily) const FamilyBadge(),
                      if (_shouldShowSharerAvatar(tx, currentUserId))
                        CircleAvatar(
                          key: const ValueKey('transaction-sharer-avatar'),
                          radius: 13,
                          backgroundColor: colors.tertiaryContainer,
                          child: Text(
                            _sharerInitials(tx),
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onTertiaryContainer,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (contextualAlert != null) ...[
            Builder(
              builder: (_) {
                final actionLabel =
                    _shouldHideContextualAlertAction(contextualAlert!)
                        ? null
                        : contextualAlert.actionLabel;
                return InAppAlertBanner(
                  title: contextualAlert.title,
                  message: contextualAlert.message,
                  actionLabel: actionLabel,
                  onAction: actionLabel == null
                      ? null
                      : () {
                          final alert = contextualAlert!;
                          if (alert.transactionId == widget.transactionId &&
                              alert.type == 'ReflectionFollowUp') {
                            _askAiReflection(dismissFollowUpAlert: true);
                            return;
                          }
                          final route = alert.actionRoute;
                          if (route != null) {
                            context.push(route);
                          }
                        },
                  onDismiss: () => ref
                      .read(dismissedAlertIdsProvider.notifier)
                      .dismiss(contextualAlert!.id),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildRegretSection(colors, textTheme),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: _loadingReflection ? null : _askAiReflection,
              child: _loadingReflection
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 20),
                        SizedBox(width: 8),
                        Text('Ask AI to Reflect'),
                      ],
                    ),
            ),
          ),
          if (_deleting) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRegretSection(ColorScheme colors, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('How did this purchase feel?', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        if (_regretLevel != null)
          _buildRegretChip(colors)
        else
          _buildRegretPicker(colors),
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

  Widget _buildRegretChip(ColorScheme colors) {
    final (icon, label, color) = _regretData(_regretLevel!);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Chip(
          avatar: Icon(icon, color: color, size: 18),
          label: Text(label),
          backgroundColor: color.withValues(alpha: 0.15),
          side: BorderSide.none,
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

  Widget _buildRegretPicker(ColorScheme colors) {
    const greenColor = Color(0xFF4CAF50);
    const amberColor = Color(0xFFFFC107);
    const redColor = Color(0xFFE53935);

    return Row(
      children: [
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => _updateRegret(0),
            style: FilledButton.styleFrom(
              backgroundColor: greenColor.withValues(alpha: 0.15),
              foregroundColor: greenColor,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sentiment_satisfied_alt, size: 18),
                SizedBox(width: 4),
                // Text('Worth It'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => _updateRegret(1),
            style: FilledButton.styleFrom(
              backgroundColor: amberColor.withValues(alpha: 0.15),
              foregroundColor: amberColor,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sentiment_neutral, size: 18),
                SizedBox(width: 4),
                // Text('Not Sure'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton.tonal(
            onPressed: () => _updateRegret(2),
            style: FilledButton.styleFrom(
              backgroundColor: redColor.withValues(alpha: 0.15),
              foregroundColor: redColor,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sentiment_dissatisfied, size: 18),
                SizedBox(width: 4),
                // Text('Regret'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  (IconData, String, Color) _regretData(int level) {
    if (level == 0) {
      return (
        Icons.sentiment_satisfied_alt,
        'Worth It',
        const Color(0xFF4CAF50)
      );
    }
    if (level == 1) {
      return (Icons.sentiment_neutral, 'Not Sure', const Color(0xFFFFC107));
    }
    return (Icons.sentiment_dissatisfied, 'Regret', const Color(0xFFE53935));
  }
}

class _TransactionDetailHero extends StatelessWidget {
  const _TransactionDetailHero({
    required this.category,
    required this.counterparty,
    required this.amountText,
    required this.amountColor,
    required this.subtitle,
  });

  final String category;
  final String counterparty;
  final String amountText;
  final Color amountColor;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final textTheme = theme.textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.navySoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.deepNavy.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        child: Column(
          children: [
            CategoryIcons.badge(category, size: 52),
            const SizedBox(height: 14),
            Text(
              counterparty,
              style: textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              amountText,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: amountColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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

  const _ReflectionSheet({
    required this.scrollController,
    required this.transactionId,
  });

  @override
  ConsumerState<_ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends ConsumerState<_ReflectionSheet> {
  AIResponse? _response;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReflection();
  }

  Future<void> _fetchReflection() async {
    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.reflection(
        transactionId: widget.transactionId,
      );
      if (!mounted) return;
      ref.read(monthlyUsageProvider.notifier).recordReflection();
      setState(() {
        _response = response;
        _loading = false;
      });
    } on DioException catch (e, s) {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: colors.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: ConscienceLoader(
                    size: 90,
                    preset: ConscienceLoaderPreset.reflection,
                    label: 'Reflection is making sense of the moment...',
                  ),
                )
              : _error != null
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
                      padding: const EdgeInsets.all(16),
                      children: [
                        const SizedBox(height: 8),
                        AiMessageBubble(
                          type: BubbleType.devil,
                          message: _response!.impulse,
                        ),
                        const SizedBox(height: 12),
                        AiMessageBubble(
                          type: BubbleType.angel,
                          message: _response!.reason,
                        ),
                        const SizedBox(height: 12),
                        AiMessageBubble(
                          type: BubbleType.neutral,
                          message: _response!.neutral,
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}
