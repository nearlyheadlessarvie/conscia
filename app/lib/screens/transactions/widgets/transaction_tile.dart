import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/family_badge.dart';
import '../../../widgets/recurring_badge.dart';

class TransactionTile extends StatelessWidget {
  final String id;
  final bool isIncome;
  final double amount;
  final String currencyCode;
  final String category;
  final String? counterparty;
  final DateTime date;
  final int? regretLevel;
  final bool isRecurring;
  final bool isFamily;
  final bool hideFamilyBadge;
  final String? sharedByUserId;
  final String? currentUserId;
  final String? sharedByInitials;

  const TransactionTile({
    super.key,
    required this.id,
    required this.isIncome,
    required this.amount,
    required this.currencyCode,
    required this.category,
    this.counterparty,
    required this.date,
    this.regretLevel,
    this.isRecurring = false,
    this.isFamily = false,
    this.hideFamilyBadge = false,
    this.sharedByUserId,
    this.currentUserId,
    this.sharedByInitials,
  });

  static IconData iconFor(String category) =>
      CategoryIcons.forCategory(category);

  static Widget badgeFor(
    String category, {
    double size = 20,
    bool filled = true,
  }) {
    return CategoryIcons.badge(
      category,
      size: size,
      filled: filled,
    );
  }

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

  String get _displayCategory {
    if (isFamily && category.startsWith('Family ')) {
      return category.substring('Family '.length);
    }
    return category;
  }

  bool get _showSharerAvatar =>
      sharedByUserId != null &&
      sharedByUserId!.isNotEmpty &&
      sharedByUserId != currentUserId;

  String get _sharerInitials {
    final explicit = sharedByInitials?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit.length <= 2
          ? explicit.toUpperCase()
          : explicit.substring(0, 2).toUpperCase();
    }

    final compactId = sharedByUserId?.replaceAll('-', '') ?? '';
    if (compactId.length >= 2) return compactId.substring(0, 2).toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayCounterparty =
        counterparty != null && counterparty!.trim().isNotEmpty
            ? counterparty!
            : 'Unknown';
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
            badgeFor(_displayCategory, size: 22, filled: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayCounterparty,
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_displayCategory · $dateStr',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (isRecurring ||
                      (isFamily && !hideFamilyBadge) ||
                      _showSharerAvatar) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (isRecurring) const RecurringBadge(compact: true),
                        if (isFamily && !hideFamilyBadge)
                          const FamilyBadge(compact: true),
                        if (_showSharerAvatar)
                          CircleAvatar(
                            key: const ValueKey('transaction-sharer-avatar'),
                            radius: 10,
                            backgroundColor: colors.tertiaryContainer,
                            child: Text(
                              _sharerInitials,
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.onTertiaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
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
