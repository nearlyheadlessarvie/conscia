import 'package:flutter/material.dart';

enum BubbleType { devil, angel, neutral }

class AiMessageBubble extends StatelessWidget {
  final BubbleType type;
  final String message;

  const AiMessageBubble({
    super.key,
    required this.type,
    required this.message,
  });

  Color _bg(Brightness brightness) {
    switch (type) {
      case BubbleType.devil:
        return brightness == Brightness.light
            ? const Color(0xFFFFF8E1)
            : const Color(0xFF3E2723);
      case BubbleType.angel:
        return brightness == Brightness.light
            ? const Color(0xFFE0F7FA)
            : const Color(0xFF0D3B47);
      case BubbleType.neutral:
        return brightness == Brightness.light
            ? const Color(0xFFF5F5F5)
            : const Color(0xFF2C2C3A);
    }
  }

  Color _accent() {
    switch (type) {
      case BubbleType.devil:
        return const Color(0xFFE65100);
      case BubbleType.angel:
        return const Color(0xFF00838F);
      case BubbleType.neutral:
        return const Color(0xFF757575);
    }
  }

  Color _textColor(Brightness brightness) {
    switch (type) {
      case BubbleType.devil:
        return brightness == Brightness.light
            ? const Color(0xFF3E2723)
            : const Color(0xFFFFE0B2);
      case BubbleType.angel:
        return brightness == Brightness.light
            ? const Color(0xFF004D40)
            : const Color(0xFFB2EBF2);
      case BubbleType.neutral:
        return brightness == Brightness.light
            ? const Color(0xFF424242)
            : const Color(0xFFBDBDBD);
    }
  }

  IconData _icon() {
    switch (type) {
      case BubbleType.devil:
        return Icons.local_fire_department;
      case BubbleType.angel:
        return Icons.shield;
      case BubbleType.neutral:
        return Icons.balance;
    }
  }

  String _label() {
    switch (type) {
      case BubbleType.devil:
        return 'Impulse';
      case BubbleType.angel:
        return 'Reason';
      case BubbleType.neutral:
        return 'Reflection';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textTheme = Theme.of(context).textTheme;
    final accent = _accent();

    return Container(
      decoration: BoxDecoration(
        color: _bg(brightness),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accent, width: 4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon(), size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                _label(),
                style: textTheme.labelMedium?.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: textTheme.bodyLarge?.copyWith(
              color: _textColor(brightness),
            ),
          ),
        ],
      ),
    );
  }
}
