import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/feeling_choice_button.dart';
import '../../../widgets/swipe_action_tile.dart';

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
    final appColors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    final formatter = NumberFormat.currency(
      symbol: currencyCode,
      decimalDigits: 2,
    );

    return Dismissible(
      key: ValueKey('regret_${counterparty}_${date.millisecondsSinceEpoch}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.18,
        DismissDirection.endToStart: 0.18,
      },
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (onWorthIt != null) {
            onWorthIt!();
          } else {
            onDismiss?.call();
          }
        } else if (direction == DismissDirection.endToStart) {
          onRegret?.call();
        }

        return false;
      },
      background: SwipeActionBackground(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 12),
        children: [
          SwipeActionTile(
            icon: Icons.thumb_up_alt_outlined,
            label: 'Worth It',
            foregroundColor: appColors.income,
            backgroundColor: appColors.incomeSoft,
            onTap: onWorthIt ?? onDismiss ?? () {},
          ),
        ],
      ),
      secondaryBackground: SwipeActionBackground(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 12),
        children: [
          SwipeActionTile(
            icon: Icons.thumb_down_alt_outlined,
            label: 'Regret',
            foregroundColor: appColors.expense,
            backgroundColor: appColors.expenseSoft,
            onTap: onRegret ?? () {},
          ),
        ],
      ),
      child: Card(
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
              if (queueHint != null) ...[
                const SizedBox(height: 14),
                Text(
                  queueHint!,
                  key: const ValueKey('dashboard-reflect-queue-hint'),
                  style: textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
