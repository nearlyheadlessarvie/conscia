import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../widgets/feeling_choice_button.dart';

class RegretPromptCard extends StatelessWidget {
  final Widget categoryBadge;
  final String counterparty;
  final double amount;
  final String currencyCode;
  final DateTime date;
  final String? queueHint;
  final VoidCallback? onWorthIt;
  final VoidCallback? onNotSure;
  final VoidCallback? onRegret;
  final VoidCallback? onDismiss;

  const RegretPromptCard({
    super.key,
    required this.categoryBadge,
    required this.counterparty,
    required this.amount,
    required this.currencyCode,
    required this.date,
    this.queueHint,
    this.onWorthIt,
    this.onNotSure,
    this.onRegret,
    this.onDismiss,
  });

  String _relativeDate() {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final formatter = NumberFormat.currency(
      symbol: currencyCode,
      decimalDigits: 2,
    );

    return Card(
      key: const ValueKey('dashboard-reflect-feature-card'),
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                categoryBadge,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        counterparty,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _relativeDate(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatter.format(amount),
                  style: textTheme.titleSmall?.copyWith(
                    color: const Color(0xFFE53935),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Was it worth it?',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Notice what this moment gave you before you decide how it felt.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FeelingChoiceButton.worthIt(
                    onPressed: onWorthIt,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FeelingChoiceButton.notSure(
                    onPressed: onNotSure,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FeelingChoiceButton.regret(
                    onPressed: onRegret,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 18,
              child: Align(
                alignment: Alignment.centerLeft,
                child: queueHint == null
                    ? const SizedBox.shrink()
                    : Text(
                        queueHint!,
                        key: const ValueKey('dashboard-reflect-queue-hint'),
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
