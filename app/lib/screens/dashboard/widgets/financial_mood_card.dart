import 'package:flutter/material.dart';
import 'package:conscia_app/models/behavioral_insights.dart';

class FinancialMoodCard extends StatelessWidget {
  final FinancialMood mood;
  final double worthItPercentage;
  final num previousMonthPercentage;

  const FinancialMoodCard({
    super.key,
    required this.mood,
    required this.worthItPercentage,
    required this.previousMonthPercentage,
  });

  Color _moodColor(Brightness brightness) {
    switch (mood) {
      case FinancialMood.confident:
        return brightness == Brightness.light
            ? const Color(0xFF4CAF50)
            : const Color(0xFF81C784);
      case FinancialMood.balanced:
        return brightness == Brightness.light
            ? const Color(0xFF2196F3)
            : const Color(0xFF64B5F6);
      case FinancialMood.cautious:
        return brightness == Brightness.light
            ? const Color(0xFFFFA726)
            : const Color(0xFFFFB74D);
      case FinancialMood.impulsive:
        return brightness == Brightness.light
            ? const Color(0xFFF44336)
            : const Color(0xFFEF5350);
    }
  }

  String _moodLabel() {
    switch (mood) {
      case FinancialMood.confident:
        return 'Confident';
      case FinancialMood.balanced:
        return 'Balanced';
      case FinancialMood.cautious:
        return 'Cautious';
      case FinancialMood.impulsive:
        return 'Impulsive';
    }
  }

  String _moodEmoji() {
    switch (mood) {
      case FinancialMood.confident:
        return '😎';
      case FinancialMood.balanced:
        return '😊';
      case FinancialMood.cautious:
        return '🤔';
      case FinancialMood.impulsive:
        return '🎉';
    }
  }

  String _trendText() {
    final diff = (worthItPercentage - previousMonthPercentage).round();
    if (diff > 0) {
      return '(+$diff% vs last month) 📈';
    } else if (diff < 0) {
      return '($diff% vs last month) 📉';
    } else {
      return '(same as last month) ➡️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final moodColor = _moodColor(brightness);

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              moodColor.withValues(alpha: 0.1),
              moodColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: moodColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '🧠 Your Financial Mood',
                          style: textTheme.labelMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _moodEmoji(),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _moodLabel(),
                          style: textTheme.headlineSmall?.copyWith(
                            color: moodColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${worthItPercentage.toStringAsFixed(0)}%',
                    style: textTheme.titleMedium?.copyWith(
                      color: moodColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${worthItPercentage.toStringAsFixed(0)}% of your decisions this week were reasoned',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _trendText(),
              style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
