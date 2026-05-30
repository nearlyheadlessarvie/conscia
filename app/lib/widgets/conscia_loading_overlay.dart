import 'dart:math' as math;

import 'package:flutter/material.dart';

class ConsciaLoadingOverlay extends StatelessWidget {
  const ConsciaLoadingOverlay({
    super.key = const ValueKey('conscia-loading-overlay'),
    this.opacity = 0.6,
  });

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: theme.scaffoldBackgroundColor.withValues(alpha: opacity),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Conscia',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                ConsciaStaggeredDotsWave(color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ConsciaStaggeredDotsWave extends StatefulWidget {
  const ConsciaStaggeredDotsWave({
    required this.color,
    super.key,
    this.dotCount = 5,
    this.dotSize = 8,
  });

  final Color color;
  final int dotCount;
  final double dotSize;

  @override
  State<ConsciaStaggeredDotsWave> createState() =>
      _ConsciaStaggeredDotsWaveState();
}

class _ConsciaStaggeredDotsWaveState extends State<ConsciaStaggeredDotsWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < widget.dotCount; index++) ...[
              _AnimatedWaveDot(
                color: widget.color,
                progress: _dotProgress(index),
                size: widget.dotSize,
              ),
              if (index != widget.dotCount - 1)
                SizedBox(width: widget.dotSize * 0.7),
            ],
          ],
        );
      },
    );
  }

  double _dotProgress(int index) {
    final phase = (_controller.value * math.pi * 2) - (index * 0.55);
    return (math.sin(phase) + 1) / 2;
  }
}

class _AnimatedWaveDot extends StatelessWidget {
  const _AnimatedWaveDot({
    required this.color,
    required this.progress,
    required this.size,
  });

  final Color color;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scale = 0.65 + (progress * 0.45);
    return Opacity(
      opacity: 0.45 + (progress * 0.55),
      child: Transform.translate(
        offset: Offset(0, -6 * progress),
        child: Transform.scale(
          scale: scale,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: size),
          ),
        ),
      ),
    );
  }
}
