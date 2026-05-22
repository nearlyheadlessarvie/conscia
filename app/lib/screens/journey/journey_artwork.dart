import 'package:flutter/material.dart';

import '../../widgets/conscia_glyph.dart';

class JourneyLevelIllustration extends StatelessWidget {
  const JourneyLevelIllustration({
    super.key,
    required this.levelKey,
    required this.size,
    required this.fallbackColor,
  });

  final String levelKey;
  final double size;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('journey-level-illustration-$levelKey'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fallbackColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Center(
        child: ConsciaGlyph.level(
          levelKey,
          color: fallbackColor,
          size: size * 0.46,
          strokeWidth: 1.9,
        ),
      ),
    );
  }
}

class JourneyQuestArt extends StatelessWidget {
  const JourneyQuestArt({
    super.key,
    required this.questKey,
    required this.size,
    required this.fallbackColor,
    required this.tintColor,
  });

  final String questKey;
  final double size;
  final Color fallbackColor;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('journey-quest-art-$questKey'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Center(
        child: ConsciaGlyph.quest(
          questKey,
          color: fallbackColor,
          size: size,
          strokeWidth: 1.9,
        ),
      ),
    );
  }
}

class JourneyBadgeArt extends StatelessWidget {
  const JourneyBadgeArt({
    super.key,
    required this.badgeKey,
    required this.size,
    required this.unlocked,
    required this.fallbackColor,
    required this.tintColor,
  });

  final String badgeKey;
  final double size;
  final bool unlocked;
  final Color fallbackColor;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('journey-badge-art-$badgeKey'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: unlocked ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Center(
        child: ConsciaGlyph.milestone(
          badgeKey,
          unlocked: unlocked,
          color: fallbackColor,
          size: size,
          strokeWidth: 1.85,
        ),
      ),
    );
  }
}

class JourneyLevelArt extends StatelessWidget {
  const JourneyLevelArt({
    super.key,
    required this.levelKey,
    required this.width,
    required this.height,
    required this.fallbackColor,
    required this.tintColor,
    this.borderRadius,
  });

  final String levelKey;
  final double width;
  final double height;
  final Color fallbackColor;
  final Color tintColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('journey-level-art-$levelKey'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: tintColor.withValues(alpha: 0.1),
        borderRadius: borderRadius ?? BorderRadius.circular(width * 0.2),
      ),
      child: Center(
        child: ConsciaGlyph.level(
          levelKey,
          color: fallbackColor,
          size: width.clamp(22, 72),
          strokeWidth: 1.85,
        ),
      ),
    );
  }
}
