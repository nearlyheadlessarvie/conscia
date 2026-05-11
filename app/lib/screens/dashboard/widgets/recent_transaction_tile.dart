import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RecentTransactionTile extends StatelessWidget {
  final String id;
  final Widget categoryBadge;
  final String counterparty;
  final String category;
  final DateTime date;
  final double amount;
  final bool isIncome;
  final String currencyCode;
  final int? regretLevel;

  const RecentTransactionTile({
    super.key,
    required this.id,
    required this.categoryBadge,
    required this.counterparty,
    required this.category,
    required this.date,
    required this.amount,
    required this.isIncome,
    required this.currencyCode,
    this.regretLevel,
  });

  Color get _regretColor {
    if (regretLevel == null) return Colors.transparent;
    if (regretLevel! == 0) return const Color(0xFF4CAF50);
    if (regretLevel! == 1) return const Color(0xFFFFC107);
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final dateStr = DateFormat.MMMd().format(date);
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );

    final amountColor =
        isIncome ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    final prefix = isIncome ? '+' : '-';

    return ListTile(
      onTap: () => context.push('/transactions/$id'),
      leading: categoryBadge,
      title: Text(counterparty, style: textTheme.titleSmall),
      subtitle: Text(
        '$category • $dateStr',
        style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$prefix$currencyCode${formatter.format(amount.abs())}',
            style: textTheme.titleSmall?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (regretLevel != null) ...[
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _regretColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
