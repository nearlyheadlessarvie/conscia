import 'package:flutter/material.dart';

import '../../widgets/conscience_mark.dart';

class OnboardingIllustration1 extends StatelessWidget {
  final double size;

  const OnboardingIllustration1({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return _IllustrationHalo(
      size: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF091A38).withValues(alpha: 0.12),
              blurRadius: size * 0.12,
              offset: Offset(0, size * 0.04),
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(
              color: const Color(0xFFB8C5E6).withValues(alpha: 0.38),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF091A38).withValues(alpha: 0.08),
                blurRadius: size * 0.09,
                offset: Offset(0, size * 0.025),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.11),
            child: ConscienceBrandIcon(size: size * 0.58),
          ),
        ),
      ),
    );
  }
}

class OnboardingIllustration2 extends StatelessWidget {
  final double size;

  const OnboardingIllustration2({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _IllustrationHalo(
      size: size,
      child: SizedBox(
        width: size,
        height: size * 0.78,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: size * 0.07,
              right: size * 0.07,
              top: size * 0.1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(size * 0.12),
                  border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.42),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF091A38).withValues(alpha: 0.09),
                      blurRadius: size * 0.085,
                      offset: Offset(0, size * 0.03),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    size * 0.085,
                    size * 0.08,
                    size * 0.085,
                    size * 0.08,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF5FF),
                              borderRadius:
                                  BorderRadius.circular(size * 0.08),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(size * 0.022),
                              child: ConscienceBrandIcon(size: size * 0.09),
                            ),
                          ),
                          const Spacer(),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F5EA),
                              borderRadius:
                                  BorderRadius.circular(size * 0.08),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: size * 0.03,
                                vertical: size * 0.015,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: size * 0.052,
                                    color: const Color(0xFF37A855),
                                  ),
                                  SizedBox(width: size * 0.01),
                                  Text(
                                    'Logged',
                                    style: TextStyle(
                                      fontSize: size * 0.034,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2D7441),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: size * 0.07),
                      Text(
                        '-PHP 180',
                        style: TextStyle(
                          fontSize: size * 0.085,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFD4483B),
                        ),
                      ),
                      SizedBox(height: size * 0.025),
                      Text(
                        'Coffee run',
                        style: TextStyle(
                          fontSize: size * 0.06,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      SizedBox(height: size * 0.014),
                      Text(
                        'Saved to your transactions in seconds.',
                        style: TextStyle(
                          fontSize: size * 0.04,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: size * 0.055),
                      _MiniChip(
                        label: 'Dining',
                        color: const Color(0xFFEAF0FF),
                        size: size,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: size * 0.03,
              bottom: size * 0.09,
              child: _FloatingAccent(
                size: size * 0.16,
                color: const Color(0xFFFFE8A6),
                icon: Icons.auto_graph_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingIllustration3 extends StatelessWidget {
  final double size;

  const OnboardingIllustration3({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _IllustrationHalo(
      size: size,
      child: SizedBox(
        width: size,
        height: size * 0.82,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: size * 0.05,
              left: size * 0.11,
              right: size * 0.02,
              child: _FeatureCard(
                size: size,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ConscienceBrandIcon(size: size * 0.1),
                        SizedBox(width: size * 0.024),
                        Expanded(
                          child: Text(
                            'Budget pulse',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: size * 0.052,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        SizedBox(width: size * 0.02),
                        Text(
                          'On track',
                          style: TextStyle(
                            fontSize: size * 0.042,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D7441),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size * 0.055),
                    _MetricBar(
                      widthFactor: 0.9,
                      color: const Color(0xFFDFE6F5),
                      height: size * 0.05,
                    ),
                    SizedBox(height: size * 0.03),
                    _MetricBar(
                      widthFactor: 0.58,
                      color: const Color(0xFF37A855),
                      height: size * 0.05,
                    ),
                    SizedBox(height: size * 0.05),
                    Row(
                      children: [
                        _MiniChip(
                          label: 'Dining',
                          color: const Color(0xFFEAF0FF),
                          size: size * 0.9,
                        ),
                        SizedBox(width: size * 0.02),
                        Text(
                          '35%',
                          style: TextStyle(
                            fontSize: size * 0.045,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D7441),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: size * 0.14,
              bottom: size * 0.02,
              child: _FeatureCard(
                size: size,
                accentColor: const Color(0xFFEAF0FF),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF4FF),
                            borderRadius: BorderRadius.circular(size * 0.06),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(size * 0.024),
                            child: Icon(
                              Icons.favorite_rounded,
                              size: size * 0.06,
                              color: const Color(0xFF27436F),
                            ),
                          ),
                        ),
                        SizedBox(width: size * 0.025),
                        Expanded(
                          child: Text(
                            'Reflection',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: size * 0.055,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: size * 0.05),
                    Text(
                      'Notice regrets, reset faster, and build habits that stick.',
                      style: TextStyle(
                        fontSize: size * 0.055,
                        height: 1.35,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationHalo extends StatelessWidget {
  const _IllustrationHalo({
    required this.size,
    required this.child,
  });

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.94,
            height: size * 0.94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: <Color>[
                  Color(0x2279E2DF),
                  Color(0x00FFFFFF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF091A38).withValues(alpha: 0.05),
                  blurRadius: size * 0.12,
                  offset: Offset(0, size * 0.03),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.size,
    required this.child,
    this.accentColor = Colors.white,
  });

  final double size;
  final Widget child;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(size * 0.11),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF091A38).withValues(alpha: 0.08),
            blurRadius: size * 0.08,
            offset: Offset(0, size * 0.03),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.09),
        child: child,
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.widthFactor,
    required this.color,
    required this.height,
  });

  final double widthFactor;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    required this.size,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.08),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size * 0.05,
          vertical: size * 0.026,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: size * 0.048,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1B2A4A),
          ),
        ),
      ),
    );
  }
}

class _FloatingAccent extends StatelessWidget {
  const _FloatingAccent({
    required this.size,
    required this.color,
    required this.icon,
  });

  final double size;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF091A38).withValues(alpha: 0.08),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: size * 0.46,
          color: const Color(0xFF27436F),
        ),
      ),
    );
  }
}
