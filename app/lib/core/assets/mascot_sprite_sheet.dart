import 'package:flutter/material.dart';

class MascotSpriteFrame extends StatelessWidget {
  const MascotSpriteFrame({
    super.key,
    required this.atlas,
    required this.frameName,
    required this.width,
    this.fit = BoxFit.contain,
    this.filterQuality = FilterQuality.high,
  });

  final MascotSpriteAtlas atlas;
  final String frameName;
  final double width;
  final BoxFit fit;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final frame = atlas.frames[frameName];
    if (frame == null) {
      return const SizedBox.shrink();
    }

    final displayHeight = width * (frame.height / frame.width);
    final sheetScale = width / frame.width;
    final scaledSheetWidth = atlas.sheetWidth * sheetScale;
    final scaledSheetHeight = atlas.sheetHeight * sheetScale;

    return SizedBox(
      width: width,
      height: displayHeight,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: scaledSheetWidth,
          maxWidth: scaledSheetWidth,
          minHeight: scaledSheetHeight,
          maxHeight: scaledSheetHeight,
          child: Transform.translate(
            offset: Offset(-frame.x * sheetScale, -frame.y * sheetScale),
            child: Image.asset(
              atlas.assetPath,
              width: scaledSheetWidth,
              height: scaledSheetHeight,
              fit: fit,
              alignment: Alignment.topLeft,
              filterQuality: filterQuality,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class MascotSpriteAtlas {
  const MascotSpriteAtlas({
    required this.assetPath,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.frames,
  });

  final String assetPath;
  final double sheetWidth;
  final double sheetHeight;
  final Map<String, MascotSpriteRect> frames;
}

class MascotSpriteRect {
  const MascotSpriteRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;
}

const devilMascotAtlas = MascotSpriteAtlas(
  assetPath: 'assets/images/sprites/devil/sprite_sheet.png',
  sheetWidth: 6270,
  sheetHeight: 3762,
  frames: {
    '1_neutral.png': MascotSpriteRect(x: 0, y: 0, width: 1254, height: 1254),
    '2_push.png': MascotSpriteRect(x: 1254, y: 0, width: 1254, height: 1254),
    '3_block.png': MascotSpriteRect(x: 2508, y: 0, width: 1254, height: 1254),
    '8_whisper.png':
        MascotSpriteRect(x: 2508, y: 1254, width: 1254, height: 1254),
  },
);

const angelMascotAtlas = MascotSpriteAtlas(
  assetPath: 'assets/images/sprites/angel/sprite_sheet.png',
  sheetWidth: 6270,
  sheetHeight: 3762,
  frames: {
    '1_neutral.png': MascotSpriteRect(x: 0, y: 0, width: 1254, height: 1254),
    '2_block.png': MascotSpriteRect(x: 1254, y: 0, width: 1254, height: 1254),
    '3_push.png': MascotSpriteRect(x: 2508, y: 0, width: 1254, height: 1254),
    '8_shield.png':
        MascotSpriteRect(x: 2508, y: 1254, width: 1254, height: 1254),
  },
);

const moneyMascotAtlas = MascotSpriteAtlas(
  assetPath: 'assets/images/sprites/money/sprite_sheet.png',
  sheetWidth: 5016,
  sheetHeight: 2508,
  frames: {
    '1_neutral.png': MascotSpriteRect(x: 0, y: 0, width: 1254, height: 1254),
    '2_right.png': MascotSpriteRect(x: 1254, y: 0, width: 1254, height: 1254),
    '3_left.png': MascotSpriteRect(x: 2508, y: 0, width: 1254, height: 1254),
    '4_save.png': MascotSpriteRect(x: 3762, y: 0, width: 1254, height: 1254),
    '5_afraid.png': MascotSpriteRect(x: 0, y: 1254, width: 1254, height: 1254),
  },
);
