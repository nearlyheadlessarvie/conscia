import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/conscience_journey.dart';
import 'journey_artwork.dart';
import 'level_up_confetti.dart';
import 'level_up_content.dart';

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
    final content = resolveLevelUpContent(summary.currentLevel.key);

    return Scaffold(
      backgroundColor: appColors.paper,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              appColors.paper,
              appColors.pageTop.withValues(alpha: 0.55),
              appColors.paper,
            ],
            stops: const [0.0, 0.48, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 560;
                      final illustrationSize = compact ? 148.0 : 188.0;
                      final illustrationGap = compact ? 20.0 : 30.0;
                      final titleStyle = compact
                          ? theme.textTheme.headlineSmall
                          : theme.textTheme.headlineMedium;
                      final payoffStyle = compact
                          ? theme.textTheme.titleSmall
                          : theme.textTheme.titleMedium;
                      final bodyStyle = compact
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.bodyLarge;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _LevelUpAtmospherePainter(appColors),
                            ),
                          ),
                          Positioned.fill(
                            child: LevelUpConfetti(compact: compact),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _IllustrationMedallion(
                                  summary: summary,
                                  diameter: illustrationSize,
                                ),
                                SizedBox(height: illustrationGap),
                                Text(
                                  content.eyebrow,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: appColors.deepNavy.withValues(alpha: 0.72),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.48,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  summary.currentLevel.title,
                                  textAlign: TextAlign.center,
                                  style: titleStyle?.copyWith(
                                    color: appColors.ink,
                                    fontWeight: FontWeight.w900,
                                    height: 1.06,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  content.payoff,
                                  textAlign: TextAlign.center,
                                  style: payoffStyle?.copyWith(
                                    color: appColors.deepNavy.withValues(alpha: 0.84),
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                SizedBox(height: compact ? 16 : 22),
                                Text(
                                  content.body,
                                  textAlign: TextAlign.center,
                                  style: bodyStyle?.copyWith(
                                    color: appColors.mutedInk,
                                    height: 1.55,
                                  ),
                                ),
                                SizedBox(height: compact ? 18 : 24),
                                _LevelProgressLine(summary: summary),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Continue your journey'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IllustrationMedallion extends StatelessWidget {
  const _IllustrationMedallion({
    required this.summary,
    required this.diameter,
  });

  final ConscienceJourneySummary summary;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).appColors;

    return Container(
      width: diameter,
      height: diameter,
      padding: EdgeInsets.all(diameter * 0.11),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            appColors.familySoft.withValues(alpha: 0.92),
            appColors.angelSoft.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(
          color: appColors.surfaceRaised.withValues(alpha: 0.9),
          width: 6,
        ),
        boxShadow: [
          BoxShadow(
            color: appColors.deepNavy.withValues(alpha: 0.08),
            blurRadius: 36,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: JourneyLevelIllustration(
        levelKey: summary.currentLevel.key,
        size: diameter * 0.78,
        fallbackColor: appColors.deepNavy,
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: appColors.surfaceRaised.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: appColors.deepNavy.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        '${summary.xpTotal} XP | $rhythmLabel',
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          color: appColors.deepNavy.withValues(alpha: 0.78),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.18,
        ),
      ),
    );
  }
}

class _LevelUpAtmospherePainter extends CustomPainter {
  const _LevelUpAtmospherePainter(this.colors);

  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final primaryPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.amberSoft.withValues(alpha: 0.9),
          colors.familySoft.withValues(alpha: 0.28),
          colors.paper.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.38),
          radius: size.shortestSide * 0.78,
        ),
      );

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.surfaceRaised.withValues(alpha: 0.55),
          colors.paper.withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.52, size.height * 0.34),
          radius: size.shortestSide * 0.42,
        ),
      );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.38),
      size.shortestSide * 0.78,
      primaryPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.52, size.height * 0.34),
      size.shortestSide * 0.42,
      haloPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LevelUpAtmospherePainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}
