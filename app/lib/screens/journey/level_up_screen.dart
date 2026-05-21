import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/conscience_journey.dart';
import '../../widgets/glyphs/conscia_glyph.dart';

class LevelUpScreen extends StatelessWidget {
  const LevelUpScreen({
    super.key,
    required this.summary,
  });

  final ConscienceJourneySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;

    return Scaffold(
      backgroundColor: appColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: appColors.ink,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _LevelUpAtmospherePainter(appColors),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _LevelGlyph(summary: summary),
                        const SizedBox(height: 30),
                        Text(
                          'You reached ${summary.currentLevel.title}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: appColors.ink,
                            fontWeight: FontWeight.w800,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your money rhythm is getting steadier.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: appColors.mutedInk,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 22),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            _levelMeaning(summary.currentLevel.key),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: appColors.mutedInk,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _LevelProgressLine(summary: summary),
                      ],
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Continue your journey'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelGlyph extends StatelessWidget {
  const _LevelGlyph({required this.summary});

  final ConscienceJourneySummary summary;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: appColors.angelSoft,
        boxShadow: [
          BoxShadow(
            color: appColors.deepNavy.withValues(alpha: 0.08),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Center(
        child: ConsciaGlyph.level(
          summary.currentLevel.key,
          color: appColors.deepNavy,
          size: 68,
        ),
      ),
    );
  }
}

class _LevelProgressLine extends StatelessWidget {
  const _LevelProgressLine({required this.summary});

  final ConscienceJourneySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.appColors;
    final rhythmLabel = summary.momentumDays == 1
        ? '1 day rhythm'
        : '${summary.momentumDays} day rhythm';

    return Text(
      '${summary.xpTotal} XP | $rhythmLabel',
      textAlign: TextAlign.center,
      style: theme.textTheme.labelLarge?.copyWith(
        color: appColors.mutedInk,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _LevelUpAtmospherePainter extends CustomPainter {
  const _LevelUpAtmospherePainter(this.colors);

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.amberSoft.withValues(alpha: 0.72),
          colors.familySoft.withValues(alpha: 0.34),
          colors.paper.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.58, size.height * 0.35),
          radius: size.shortestSide * 0.72,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.35),
      size.shortestSide * 0.72,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelUpAtmospherePainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

String _levelMeaning(String levelKey) {
  return switch (levelKey) {
    'awakening' =>
      'You are beginning to notice the small money moments that shape your days.',
    'impulse_spotter' || 'impulse-spotter' =>
      'You are catching impulses earlier and giving yourself more room to choose.',
    'budget_guardian' || 'budget-guardian' =>
      'You are building steadier money boundaries without turning every choice into pressure.',
    'conscience_captain' || 'conscience-captain' =>
      'You are steering with more clarity, using signals from your own habits instead of noise.',
    'money_monk' || 'money-monk' =>
      'You are finding a calmer rhythm with money, one considered moment at a time.',
    _ =>
      'This level marks a quieter kind of progress: more awareness, more steadiness, and more trust in your rhythm.',
  };
}
