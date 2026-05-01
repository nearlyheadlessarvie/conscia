import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegretPromptCard extends StatelessWidget {
  final IconData categoryIcon;
  final String merchant;
  final double amount;
  final String currencyCode;
  final DateTime date;
  final VoidCallback? onWorthIt;
  final VoidCallback? onNotSure;
  final VoidCallback? onRegret;
  final VoidCallback? onDismiss;

  const RegretPromptCard({
    super.key,
    required this.categoryIcon,
    required this.merchant,
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
    final textTheme = Theme.of(context).textTheme;

    final formatter = NumberFormat.currency(
      symbol: currencyCode,
      decimalDigits: 2,
    );

    return Dismissible(
      key: ValueKey('regret_${merchant}_${date.millisecondsSinceEpoch}'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.check, color: Color(0xFF4CAF50)),
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
                  CircleAvatar(
                    backgroundColor: colors.primaryContainer,
                    child: Icon(categoryIcon, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(merchant, style: textTheme.titleSmall),
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
                    child: _ActionButton(
                      label: 'Worth It',
                      color: const Color(0xFF4CAF50),
                      icon: Icons.thumb_up_outlined,
                      onTap: onWorthIt,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Not Sure',
                      color: const Color(0xFFFFC107),
                      icon: Icons.help_outline,
                      onTap: onNotSure,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Regret',
                      color: const Color(0xFFE53935),
                      icon: Icons.thumb_down_outlined,
                      onTap: onRegret,
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

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
