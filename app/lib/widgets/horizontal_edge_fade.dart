import 'dart:math' as math;

import 'package:flutter/material.dart';

class HorizontalEdgeFade extends StatelessWidget {
  const HorizontalEdgeFade({
    super.key,
    required this.child,
    this.fadeWidth = 28,
  });

  final Widget child;
  final double fadeWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fadeStop = width.isFinite && width > 0
            ? math.max(0.0, 1 - (fadeWidth / width))
            : 0.92;

        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white,
              Colors.white,
              Colors.white.withValues(alpha: 0),
            ],
            stops: [0, fadeStop, 1],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: child,
        );
      },
    );
  }
}
