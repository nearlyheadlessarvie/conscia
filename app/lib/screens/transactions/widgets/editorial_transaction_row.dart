import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../services/transaction_service.dart';

class EditorialTransactionRowData {
  const EditorialTransactionRowData({
    required this.id,
    required this.isIncome,
    required this.amount,
    required this.currencyCode,
    required this.category,
    required this.title,
    this.regretLevel,
    this.isRecurring = false,
    this.isFamily = false,
  });

  factory EditorialTransactionRowData.fromTransaction(
    Transaction transaction, {
    String? displayCategory,
  }) {
    final title = transaction.description.trim().isEmpty
        ? 'Unknown'
        : transaction.description.trim();

    return EditorialTransactionRowData(
      id: transaction.id,
      isIncome: transaction.type == 'income',
      amount: transaction.amount,
      currencyCode: transaction.currencyCode,
      category: displayCategory ?? displayCategoryForTransaction(transaction),
      title: title,
      regretLevel: transaction.regretLevel,
      isRecurring: transaction.isRecurring,
      isFamily: transaction.isFamily,
    );
  }

  final String id;
  final bool isIncome;
  final double amount;
  final String currencyCode;
  final String category;
  final String title;
  final int? regretLevel;
  final bool isRecurring;
  final bool isFamily;
}

String displayCategoryForTransaction(Transaction transaction) {
  if (transaction.isFamily && transaction.category.startsWith('Family ')) {
    return transaction.category.substring('Family '.length);
  }
  return transaction.category;
}

class EditorialTransactionRowsGroup extends StatelessWidget {
  const EditorialTransactionRowsGroup({
    super.key,
    required this.children,
    this.horizontalPadding = 16,
    this.verticalPadding = 4,
  });

  final List<Widget> children;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final separatedChildren = <Widget>[];

    for (var index = 0; index < children.length; index++) {
      separatedChildren.add(children[index]);
      if (index < children.length - 1) {
        separatedChildren.add(
          Divider(
            height: 10,
            thickness: 1,
            color: colors.border,
          ),
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: separatedChildren,
      ),
    );
  }
}

class EditorialTransactionRow extends StatelessWidget {
  const EditorialTransactionRow({
    super.key,
    required this.data,
    this.locale,
    this.onTap,
  });

  final EditorialTransactionRowData data;
  final String? locale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final amountColor = data.isIncome ? colors.income : colors.expense;
    final signedAmount = data.isIncome ? data.amount.abs() : -data.amount.abs();
    final amountText = _formatSignedAmount(signedAmount);

    final rowStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return InkWell(
      onTap: onTap ?? () => context.push('/transactions/${data.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CategoryIcons.badge(data.category, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: rowStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    data.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.mutedInk,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountText,
                  style: rowStyle?.copyWith(color: amountColor),
                ),
                if (data.isFamily ||
                    data.isRecurring ||
                    data.regretLevel != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (data.isFamily)
                        _IconTag(
                          key: const ValueKey('family-transaction-badge'),
                          icon: Icons.people_rounded,
                          color: colors.family,
                        ),
                      if (data.isRecurring)
                        _IconTag(
                          key: const ValueKey('recurring-transaction-badge'),
                          icon: Icons.repeat_rounded,
                          color: colors.deepNavy,
                        ),
                      if (data.regretLevel != null)
                        _RegretIconTag(
                          key: const ValueKey('regret-transaction-badge'),
                          icon: _regretIcon(data.regretLevel!),
                          color: _regretColor(data.regretLevel!, colors),
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
    if (level == 0) return Icons.sentiment_satisfied_alt;
    if (level == 1) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }

  String _formatSignedAmount(double signedAmount) {
    try {
      return CurrencyFormatter.formatSigned(
        signedAmount,
        currencyCode: data.currencyCode,
        locale: locale,
      );
    } catch (_) {
      return CurrencyFormatter.formatSigned(
        signedAmount,
        currencyCode: data.currencyCode,
      );
    }
  }
}

class _IconTag extends StatelessWidget {
  const _IconTag({super.key, required this.icon, required this.color});

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

class _RegretIconTag extends StatelessWidget {
  const _RegretIconTag({
    super.key,
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
