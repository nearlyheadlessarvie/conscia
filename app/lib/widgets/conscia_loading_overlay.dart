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
                ConsciaStaggeredDotsWave(
                  color: colors.primary,
                  size: 38,
                ),
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
    this.size = 38,
  });

  final Color color;
  final double size;

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
      duration: const Duration(milliseconds: 1600),
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
        final oddHeight = widget.size * 0.4;
        final evenHeight = widget.size * 0.7;

        return SizedBox.square(
          dimension: widget.size,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _WaveBar(
                controllerValue: _controller.value,
                color: widget.color,
                size: widget.size,
                maxHeight: oddHeight,
                heightInterval: const Interval(0.0, 0.1),
                offsetInterval: const Interval(0.18, 0.28),
                reverseHeightInterval: const Interval(0.28, 0.38),
                reverseOffsetInterval: const Interval(0.47, 0.57),
              ),
              _WaveBar(
                controllerValue: _controller.value,
                color: widget.color,
                size: widget.size,
                maxHeight: evenHeight,
                heightInterval: const Interval(0.09, 0.19),
                offsetInterval: const Interval(0.27, 0.37),
                reverseHeightInterval: const Interval(0.37, 0.47),
                reverseOffsetInterval: const Interval(0.56, 0.66),
              ),
              _WaveBar(
                controllerValue: _controller.value,
                color: widget.color,
                size: widget.size,
                maxHeight: oddHeight,
                heightInterval: const Interval(0.18, 0.28),
                offsetInterval: const Interval(0.36, 0.46),
                reverseHeightInterval: const Interval(0.46, 0.56),
                reverseOffsetInterval: const Interval(0.65, 0.75),
              ),
              _WaveBar(
                controllerValue: _controller.value,
                color: widget.color,
                size: widget.size,
                maxHeight: evenHeight,
                heightInterval: const Interval(0.27, 0.37),
                offsetInterval: const Interval(0.45, 0.55),
                reverseHeightInterval: const Interval(0.55, 0.65),
                reverseOffsetInterval: const Interval(0.74, 0.84),
              ),
              _WaveBar(
                controllerValue: _controller.value,
                color: widget.color,
                size: widget.size,
                maxHeight: oddHeight,
                heightInterval: const Interval(0.36, 0.46),
                offsetInterval: const Interval(0.54, 0.64),
                reverseHeightInterval: const Interval(0.64, 0.74),
                reverseOffsetInterval: const Interval(0.83, 0.93),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({
    required this.color,
    required this.size,
    required this.controllerValue,
    required this.maxHeight,
    required this.heightInterval,
    required this.offsetInterval,
    required this.reverseHeightInterval,
    required this.reverseOffsetInterval,
  });

  final Color color;
  final double size;
  final double controllerValue;
  final double maxHeight;
  final Interval heightInterval;
  final Interval offsetInterval;
  final Interval reverseHeightInterval;
  final Interval reverseOffsetInterval;

  @override
  Widget build(BuildContext context) {
    final baseHeight = size * 0.13;
    final maxOffset = -(size * 0.20);
    final isRising = controllerValue <= offsetInterval.end;
    final height = isRising
        ? _lerp(baseHeight, maxHeight, _intervalValue(heightInterval))
        : _lerp(maxHeight, baseHeight, _intervalValue(reverseHeightInterval));
    final offsetY = isRising
        ? _lerp(0, maxOffset, _intervalValue(offsetInterval))
        : _lerp(maxOffset, 0, _intervalValue(reverseOffsetInterval));

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size),
        ),
        child: SizedBox(
          width: baseHeight,
          height: height,
        ),
      ),
    );
  }

  double _intervalValue(Interval interval) {
    if (controllerValue <= interval.begin) return 0;
    if (controllerValue >= interval.end) return 1;

    final progress =
        (controllerValue - interval.begin) / (interval.end - interval.begin);
    return Curves.easeInOut.transform(progress);
  }

  static double _lerp(double start, double end, double value) =>
      start + ((end - start) * value);
}
