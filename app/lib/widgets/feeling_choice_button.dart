import 'package:flutter/material.dart';

class FeelingChoiceButton extends StatelessWidget {
  const FeelingChoiceButton.worthIt({
    super.key,
    this.onPressed,
  })  : label = 'Worth It',
        icon = Icons.sentiment_satisfied_alt,
        color = const Color(0xFF4CAF50);

  const FeelingChoiceButton.notSure({
    super.key,
    this.onPressed,
  })  : label = 'Not Sure',
        icon = Icons.sentiment_neutral,
        color = const Color(0xFFFFC107);

  const FeelingChoiceButton.regret({
    super.key,
    this.onPressed,
  })  : label = 'Regret',
        icon = Icons.sentiment_dissatisfied,
        color = const Color(0xFFE53935);

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        shape: const StadiumBorder(),
        textStyle: textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
