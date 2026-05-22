import 'package:flutter/material.dart';

import '../../widgets/glyphs/conscia_glyph.dart';
import '../../widgets/glyphs/conscia_glyph_mapper.dart';

class JourneySpriteAsset {
  const JourneySpriteAsset({
    required this.assetPath,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.x,
    required this.y,
    required this.frameWidth,
    required this.frameHeight,
  });

  final String assetPath;
  final double sheetWidth;
  final double sheetHeight;
  final double x;
  final double y;
  final double frameWidth;
  final double frameHeight;
}

const _portraitSheetWidth = 6270.0;
const _portraitSheetHeight = 2508.0;
const _moneySheetWidth = 5016.0;
const _moneySheetHeight = 2508.0;
const _frameSize = 1254.0;

const _angelSheet = 'assets/images/sprites/angel/profile_sprite_sheet.png';
const _moneySheet = 'assets/images/sprites/money/sprite_sheet.png';

JourneySpriteAsset _sheetFrame(
  String assetPath,
  double sheetWidth,
  double sheetHeight,
  int column,
  int row,
) {
  return JourneySpriteAsset(
    assetPath: assetPath,
    sheetWidth: sheetWidth,
    sheetHeight: sheetHeight,
    x: column * _frameSize,
    y: row * _frameSize,
    frameWidth: _frameSize,
    frameHeight: _frameSize,
  );
}

final _angelNeutral = _sheetFrame(
  _angelSheet,
  _portraitSheetWidth,
  _portraitSheetHeight,
  0,
  0,
);
final _angelFierce = _sheetFrame(
  _angelSheet,
  _portraitSheetWidth,
  _portraitSheetHeight,
  1,
  0,
);
final _angelJoy = _sheetFrame(
  _angelSheet,
  _portraitSheetWidth,
  _portraitSheetHeight,
  2,
  0,
);
final _angelWink = _sheetFrame(
  _angelSheet,
  _portraitSheetWidth,
  _portraitSheetHeight,
  4,
  0,
);
final _angelSleepy = _sheetFrame(
  _angelSheet,
  _portraitSheetWidth,
  _portraitSheetHeight,
  2,
  1,
);
final _angelConfused = _sheetFrame(
  _angelSheet,
  _portraitSheetWidth,
  _portraitSheetHeight,
  3,
  1,
);
final _angelLove = _sheetFrame(
  _angelSheet,
  _portraitSheetWidth,
  _portraitSheetHeight,
  4,
  1,
);

final _moneyNeutral = _sheetFrame(
  _moneySheet,
  _moneySheetWidth,
  _moneySheetHeight,
  0,
  0,
);
final _moneyRight = _sheetFrame(
  _moneySheet,
  _moneySheetWidth,
  _moneySheetHeight,
  1,
  0,
);
final _moneyLeft = _sheetFrame(
  _moneySheet,
  _moneySheetWidth,
  _moneySheetHeight,
  2,
  0,
);
final _moneySave = _sheetFrame(
  _moneySheet,
  _moneySheetWidth,
  _moneySheetHeight,
  3,
  0,
);
final _moneyAfraid = _sheetFrame(
  _moneySheet,
  _moneySheetWidth,
  _moneySheetHeight,
  0,
  1,
);
final _moneyBurst = _sheetFrame(
  _moneySheet,
  _moneySheetWidth,
  _moneySheetHeight,
  2,
  1,
);
final _moneyFolded = _sheetFrame(
  _moneySheet,
  _moneySheetWidth,
  _moneySheetHeight,
  3,
  1,
);

JourneySpriteAsset? resolveLevelIllustrationSprite(String key) {
  return switch (ConsciaGlyphMapper.normalize(key)) {
    'awakening' => _angelNeutral,
    'impulse-spotter' => _angelConfused,
    'budget-guardian' => _angelFierce,
    'conscience-captain' => _angelJoy,
    'money-monk' => _angelSleepy,
    _ => null,
  };
}

JourneySpriteAsset? resolveLevelTokenSprite(String key) {
  return switch (ConsciaGlyphMapper.normalize(key)) {
    'awakening' => _moneyNeutral,
    'impulse-spotter' => _moneyLeft,
    'budget-guardian' => _moneySave,
    'conscience-captain' => _moneyRight,
    'money-monk' => _moneyFolded,
    _ => null,
  };
}

JourneySpriteAsset? resolveQuestSprite(String key) {
  return switch (ConsciaGlyphMapper.normalize(key)) {
    'reflect-three-purchases' => _moneyNeutral,
    'check-before-purchase' => _moneyAfraid,
    'review-regret-pattern' => _moneyLeft,
    'read-two-insights' => _moneyRight,
    'create-budget-guardrail' => _moneySave,
    'send-family-invite' => _angelLove,
    'add-family-expense' => _moneyBurst,
    _ => _moneyFolded,
  };
}

JourneySpriteAsset? resolveBadgeSprite(String key) {
  return switch (ConsciaGlyphMapper.normalize(key)) {
    'first-reflection' => _moneyNeutral,
    'pause-before-purchase' || 'pre-purchase-habit' => _moneyAfraid,
    'budget-rescuer' => _moneySave,
    'regret-pattern-spotted' || 'reflection-streak' => _moneyLeft,
    'worth-it-week' => _moneyBurst,
    'family-founder' || 'family-planner' => _angelLove,
    'insight-reader' || 'deep-thinker' => _angelWink,
    _ => _moneyFolded,
  };
}

class JourneySpriteFrame extends StatelessWidget {
  const JourneySpriteFrame({
    super.key,
    required this.sprite,
    required this.width,
    required this.height,
    this.borderRadius,
    this.color,
    this.colorBlendMode,
    this.opacity = 1,
  });

  final JourneySpriteAsset sprite;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Color? color;
  final BlendMode? colorBlendMode;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final scaleX = width / sprite.frameWidth;
    final scaleY = height / sprite.frameHeight;
    final image = Positioned(
      left: -(sprite.x * scaleX),
      top: -(sprite.y * scaleY),
      width: sprite.sheetWidth * scaleX,
      height: sprite.sheetHeight * scaleY,
      child: Image.asset(
        sprite.assetPath,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
        color: color,
        colorBlendMode: colorBlendMode,
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: Opacity(
        opacity: opacity,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [image],
          ),
        ),
      ),
    );
  }
}

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
    final sprite = resolveLevelIllustrationSprite(levelKey);
    if (sprite == null) {
      return ConsciaGlyph.level(
        levelKey,
        color: fallbackColor,
        size: size * 0.42,
      );
    }

    return JourneySpriteFrame(
      key: ValueKey('journey-level-illustration-$levelKey'),
      sprite: sprite,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size * 0.32),
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
    final sprite = resolveQuestSprite(questKey);
    if (sprite == null) {
      return ConsciaGlyph.quest(
        questKey,
        color: fallbackColor,
        size: size,
      );
    }

    return JourneySpriteFrame(
      key: ValueKey('journey-quest-art-$questKey'),
      sprite: sprite,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size * 0.32),
      color: tintColor,
      colorBlendMode: BlendMode.modulate,
      opacity: 0.92,
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
    final sprite = unlocked ? resolveBadgeSprite(badgeKey) : null;
    if (sprite == null) {
      return ConsciaGlyph.milestone(
        badgeKey,
        unlocked: unlocked,
        color: fallbackColor,
        size: size,
      );
    }

    return JourneySpriteFrame(
      key: ValueKey('journey-badge-art-$badgeKey'),
      sprite: sprite,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size * 0.32),
      color: tintColor,
      colorBlendMode: BlendMode.modulate,
      opacity: 0.9,
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
    final sprite = resolveLevelTokenSprite(levelKey);
    if (sprite == null) {
      return ConsciaGlyph.level(
        levelKey,
        color: fallbackColor,
        size: width.clamp(22, 72),
      );
    }

    return JourneySpriteFrame(
      key: ValueKey('journey-level-art-$levelKey'),
      sprite: sprite,
      width: width,
      height: height,
      borderRadius: borderRadius ?? BorderRadius.circular(width * 0.2),
      color: tintColor,
      colorBlendMode: BlendMode.modulate,
      opacity: 0.88,
    );
  }
}
