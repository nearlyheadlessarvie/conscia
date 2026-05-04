import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/utils/currency_formatter.dart';

class TransactionTile extends StatelessWidget {
  final String id;
  final bool isIncome;
  final double amount;
  final String currencyCode;
  final String category;
  final String? merchant;
  final DateTime date;
  final int? regretLevel;

  const TransactionTile({
    super.key,
    required this.id,
    required this.isIncome,
    required this.amount,
    required this.currencyCode,
    required this.category,
    this.merchant,
    required this.date,
    this.regretLevel,
  });

  static IconData iconFor(String category) =>
      CategoryIcons.forCategory(category);

  Color _amountColor(ColorScheme colors) {
    if (!isIncome) {
      return colors.brightness == Brightness.light
          ? const Color(0xFFE53935)
          : const Color(0xFFEF9A9A);
    }
    return colors.brightness == Brightness.light
        ? const Color(0xFF4CAF50)
        : const Color(0xFF81C784);
  }

  Color? _regretDotColor() {
    if (regretLevel == null) return null;
    if (regretLevel! == 0) return const Color(0xFF4CAF50);
    if (regretLevel! == 1) return const Color(0xFFFFC107);
    return const Color(0xFFE53935);
  }

  String? _regretLabel() {
    if (regretLevel == null) return null;
    if (regretLevel! == 0) return 'Worth It';
    if (regretLevel! == 1) return 'Not Sure';
    return 'Regret';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final amountText = isIncome
        ? '+${CurrencyFormatter.format(amount.abs(), currencyCode: currencyCode)}'
        : '-${CurrencyFormatter.format(amount.abs(), currencyCode: currencyCode)}';
    final dateStr = DateFormat.MMMd().format(date);

    return InkWell(
      onTap: () => context.push('/transactions/$id'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colors.primaryContainer,
              child: Icon(
                iconFor(category),
                size: 20,
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant ?? 'Unknown',
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$category · $dateStr',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amountText,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _amountColor(colors),
                      ),
                    ),
                    if (_regretDotColor() != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _regretDotColor(),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currencyCode,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (_regretLabel() != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        _regretLabel()!,
                        style: textTheme.labelSmall?.copyWith(
                          color: _regretDotColor(),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
