import 'package:flutter/material.dart';

class OnboardingIllustration1 extends StatelessWidget {
  final double size;

  const OnboardingIllustration1({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return _CalmOnboardingScene(
      size: size,
      icon: Icons.spa_outlined,
      title: 'A calmer start',
      lineWidths: const [0.78, 0.58],
      accent: const Color(0xFF7BAF9E),
      glow: const Color(0xFFFFD99B),
    );
  }
}

class OnboardingIllustration2 extends StatelessWidget {
  final double size;

  const OnboardingIllustration2({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return _CalmOnboardingScene(
      size: size,
      icon: Icons.auto_graph_rounded,
      title: 'Patterns, softly',
      lineWidths: const [0.9, 0.64, 0.46],
      accent: const Color(0xFF8DA2E8),
      glow: const Color(0xFFC9E7F2),
      showChart: true,
    );
  }
}

class OnboardingIllustration3 extends StatelessWidget {
  final double size;

  const OnboardingIllustration3({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return _CalmOnboardingScene(
      size: size,
      icon: Icons.shield_outlined,
      title: 'Gentle guardrails',
      lineWidths: const [0.72, 0.86],
      accent: const Color(0xFFE8A15F),
      glow: const Color(0xFFE9EDFF),
      showRing: true,
    );
  }
}

class _CalmOnboardingScene extends StatelessWidget {
  const _CalmOnboardingScene({
    required this.size,
    required this.icon,
    required this.title,
    required this.lineWidths,
    required this.accent,
    required this.glow,
    this.showChart = false,
    this.showRing = false,
  });

  final double size;
  final IconData icon;
  final String title;
  final List<double> lineWidths;
  final Color accent;
  final Color glow;
  final bool showChart;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final width = size * 1.22;
    final height = size * 0.94;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.11),
                border: Border.all(
                  color: const Color(0xFFDAE2F6).withValues(alpha: 0.78),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFF7F9F2),
                    Color(0xFFF3F7FF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF091A38).withValues(alpha: 0.08),
                    blurRadius: size * 0.1,
                    offset: Offset(0, size * 0.03),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: size * 0.06,
            top: size * 0.06,
            right: size * 0.06,
            bottom: size * 0.06,
            child: CustomPaint(
              painter: _CalmScenePainter(accent: accent, glow: glow),
            ),
          ),
          Positioned(
            left: size * 0.08,
            top: size * 0.12,
            child: _SoftNoteCard(
              size: size,
              title: title,
              icon: icon,
              accent: accent,
              lineWidths: lineWidths,
            ),
          ),
          if (showChart)
            Positioned(
              right: size * 0.1,
              bottom: size * 0.16,
              child: _MiniChart(size: size, accent: accent),
            ),
          if (showRing)
            Positioned(
              right: size * 0.12,
              bottom: size * 0.13,
              child: _ProgressRing(size: size, accent: accent),
            ),
          if (!showChart && !showRing)
            Positioned(
              right: size * 0.1,
              bottom: size * 0.13,
              child: _QuietCoinStack(size: size, accent: accent),
            ),
        ],
      ),
    );
  }
}

class _SoftNoteCard extends StatelessWidget {
  const _SoftNoteCard({
    required this.size,
    required this.title,
    required this.icon,
    required this.accent,
    required this.lineWidths,
  });

  final double size;
  final String title;
  final IconData icon;
  final Color accent;
  final List<double> lineWidths;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(size * 0.1),
        border: Border.all(
          color: const Color(0xFFD9E1F4).withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF091A38).withValues(alpha: 0.08),
            blurRadius: size * 0.08,
            offset: Offset(0, size * 0.025),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.06),
        child: SizedBox(
          width: size * 0.42,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: size * 0.13,
                    height: size * 0.13,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(size * 0.05),
                    ),
                    child: Icon(icon, size: size * 0.07, color: accent),
                  ),
                  SizedBox(width: size * 0.035),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: size * 0.042,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF18245C),
                        height: 1.08,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: size * 0.05),
              for (final widthFactor in lineWidths) ...[
                FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Container(
                    height: size * 0.028,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE4F7),
                      borderRadius: BorderRadius.circular(size * 0.03),
                    ),
                  ),
                ),
                SizedBox(height: size * 0.022),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuietCoinStack extends StatelessWidget {
  const _QuietCoinStack({required this.size, required this.accent});

  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.34,
      height: size * 0.24,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          for (var index = 0; index < 4; index++)
            Positioned(
              bottom: index * size * 0.032,
              child: Container(
                width: size * (0.25 - index * 0.018),
                height: size * 0.052,
                decoration: BoxDecoration(
                  color: Color.lerp(accent, const Color(0xFFFFD99B), 0.46),
                  borderRadius: BorderRadius.circular(size * 0.04),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniChart extends StatelessWidget {
  const _MiniChart({required this.size, required this.accent});

  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final heights = [0.28, 0.46, 0.34, 0.62];
    return Container(
      width: size * 0.34,
      height: size * 0.28,
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(size * 0.09),
        border: Border.all(color: const Color(0xFFD9E1F4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final height in heights)
            Container(
              width: size * 0.04,
              height: size * height * 0.22,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(size * 0.03),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.size, required this.accent});

  final double size;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.33,
      height: size * 0.33,
      child: CustomPaint(
        painter: _ProgressRingPainter(accent),
        child: Center(
          child: Icon(
            Icons.check_rounded,
            color: accent,
            size: size * 0.12,
          ),
        ),
      ),
    );
  }
}

class _CalmScenePainter extends CustomPainter {
  const _CalmScenePainter({required this.accent, required this.glow});

  final Color accent;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          glow.withValues(alpha: 0.7),
          glow.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.72, size.height * 0.38),
          radius: size.width * 0.44,
        ),
      );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.38),
      size.width * 0.44,
      glowPaint,
    );

    final wavePaint = Paint()
      ..color = accent.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final wave = Path()
      ..moveTo(0, size.height * 0.64)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.5,
        size.width * 0.52,
        size.height * 0.76,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(wave, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _CalmScenePainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.glow != glow;
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset.zero & size;
    final base = Paint()
      ..color = const Color(0xFFDDE4F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final progress = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(stroke), 0, 6.28, false, base);
    canvas.drawArc(rect.deflate(stroke), -1.57, 4.45, false, progress);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
