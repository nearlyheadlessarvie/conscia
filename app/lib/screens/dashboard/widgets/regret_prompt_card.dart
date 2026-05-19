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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  categoryBadge,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(counterparty, style: textTheme.titleSmall),
                        Text(
                          _relativeDate(),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatter.format(amount),
                    style: textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Was it worth it?',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}
