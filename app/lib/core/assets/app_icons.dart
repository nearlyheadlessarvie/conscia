import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

const _brandIconAsset = 'assets/images/app_icon.svg';

class ConsciaSvgLogo extends StatelessWidget {
  const ConsciaSvgLogo({
    super.key,
    required this.size,
    this.showText = false,
  });

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final totalHeight = showText ? size + 32 : size;
    return SizedBox(
      width: size,
      height: totalHeight,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF091A38).withValues(alpha: 0.08),
                  blurRadius: size * 0.12,
                  offset: Offset(0, size * 0.04),
                ),
              ],
            ),
            child: SizedBox(
              width: size,
              height: size,
              child: SvgPicture.asset(
                _brandIconAsset,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (showText) ...[
            const SizedBox(height: 8),
            Text(
              'Conscia',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: size * 0.14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A237E),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class ImpulseFaceIcon extends StatelessWidget {
  const ImpulseFaceIcon({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: HugeIconsStrokeRounded.alert02,
      color: const Color(0xFFE65100),
      size: size,
      strokeWidth: 1.9,
    );
  }
}

class ReasonFaceIcon extends StatelessWidget {
  const ReasonFaceIcon({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: HugeIconsStrokeRounded.shield01,
      color: const Color(0xFF00838F),
      size: size,
      strokeWidth: 1.9,
    );
  }
}
