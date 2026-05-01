import 'dart:math' as math;

import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulsingDot(controller: _controller, delayMs: 0),
        const SizedBox(width: 6),
        _PulsingDot(controller: _controller, delayMs: 200),
        const SizedBox(width: 6),
        _PulsingDot(controller: _controller, delayMs: 400),
      ],
    );
  }
}

class _PulsingDot extends AnimatedWidget {
  final int delayMs;

  const _PulsingDot({
    required AnimationController controller,
    required this.delayMs,
  }) : super(listenable: controller);

  @override
  Widget build(BuildContext context) {
    final controller = listenable as AnimationController;
    final t = ((controller.value * 600 - delayMs) % 600) / 600;
    final scale = 0.5 + 0.5 * ((1 + math.sin(t * 2 * math.pi)) / 2);

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
