import 'package:flutter/material.dart';

import 'mascot_sprite_sheet.dart';

const _devilNeutralAsset = '1_neutral.png';
const _devilWhisperAsset = '8_whisper.png';
const _angelNeutralAsset = '1_neutral.png';
const _angelShieldAsset = '8_shield.png';
const _moneyNeutralAsset = '1_neutral.png';
const _moneySaveAsset = '4_save.png';

class OnboardingIllustration1 extends StatelessWidget {
  final double size;

  const OnboardingIllustration1({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return _StoryboardScene(
      size: size,
      mood: const _SceneMood(
        red: 0.48,
        gold: 0.42,
        blue: 0.44,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: size * 0.01,
            bottom: size * 0.035,
            child: _StoryAsset(
              atlas: devilMascotAtlas,
              frameName: _devilNeutralAsset,
              width: size * 0.58,
            ),
          ),
          Positioned(
            left: size * 0.37,
            bottom: size * 0.05,
            child: _StoryAsset(
              atlas: moneyMascotAtlas,
              frameName: _moneyNeutralAsset,
              width: size * 0.42,
            ),
          ),
          Positioned(
            right: size * 0.06,
            bottom: size * 0.14,
            child: _StoryAsset(
              atlas: angelMascotAtlas,
              frameName: _angelNeutralAsset,
              width: size * 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingIllustration2 extends StatelessWidget {
  final double size;

  const OnboardingIllustration2({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return _StoryboardScene(
      size: size,
      mood: const _SceneMood(
        red: 0.58,
        gold: 0.36,
        blue: 0.3,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: size * 0.01,
            bottom: size * 0.03,
            child: _StoryAsset(
              atlas: devilMascotAtlas,
              frameName: _devilWhisperAsset,
              width: size * 0.62,
            ),
          ),
          Positioned(
            left: size * 0.38,
            bottom: size * 0.06,
            child: _StoryAsset(
              atlas: moneyMascotAtlas,
              frameName: _moneySaveAsset,
              width: size * 0.38,
              foreground: true,
            ),
          ),
          Positioned(
            right: size * 0.02,
            top: size * 0.06,
            child: _SceneUiCard(
              size: size,
              title: 'Logged in seconds',
              lines: const [1.0, 0.68, 0.52],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingIllustration3 extends StatelessWidget {
  final double size;

  const OnboardingIllustration3({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return _StoryboardScene(
      size: size,
      mood: const _SceneMood(
        red: 0.24,
        gold: 0.38,
        blue: 0.6,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: size * 0.04,
            top: size * 0.08,
            child: _SceneUiCard(
              size: size,
              title: 'Reflection + budgets',
              lines: const [1.0, 0.84, 0.58],
            ),
          ),
          Positioned(
            right: size * 0.01,
            bottom: 0,
            child: _StoryAsset(
              atlas: angelMascotAtlas,
              frameName: _angelShieldAsset,
              width: size * 0.64,
            ),
          ),
          Positioned(
            left: size * 0.36,
            bottom: size * 0.05,
            child: _StoryAsset(
              atlas: moneyMascotAtlas,
              frameName: _moneyNeutralAsset,
              width: size * 0.38,
              foreground: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryboardScene extends StatelessWidget {
  const _StoryboardScene({
    required this.size,
    required this.mood,
    required this.child,
  });

  final double size;
  final _SceneMood mood;
  final Widget child;

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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFDFEFF),
                    Color(0xFFF5F8FF),
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
            left: size * 0.02,
            right: size * 0.5,
            top: size * 0.1,
            bottom: size * 0.1,
            child: _GlowBlob(
              color: const Color(0xFFFF8E7C).withValues(alpha: mood.red),
              blurScale: 1.2,
            ),
          ),
          Positioned(
            left: size * 0.37,
            right: size * 0.37,
            top: 0,
            bottom: size * 0.22,
            child: _GlowBlob(
              color: const Color(0xFFFFDD7B).withValues(alpha: mood.gold),
              blurScale: 1.18,
            ),
          ),
          Positioned(
            left: size * 0.52,
            right: size * 0.03,
            top: size * 0.08,
            bottom: size * 0.08,
            child: _GlowBlob(
              color: const Color(0xFF7ACDFF).withValues(alpha: mood.blue),
              blurScale: 1.22,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.color,
    this.blurScale = 1,
  });

  final Color color;
  final double blurScale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: color.a * 0.42),
            blurRadius: 52 * blurScale,
            spreadRadius: 12 * blurScale,
          ),
        ],
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: color.a * 0.42),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _SceneMood {
  const _SceneMood({
    required this.red,
    required this.gold,
    required this.blue,
  });

  final double red;
  final double gold;
  final double blue;
}

class _StoryAsset extends StatelessWidget {
  const _StoryAsset({
    required this.atlas,
    required this.frameName,
    required this.width,
    this.foreground = false,
  });

  final MascotSpriteAtlas atlas;
  final String frameName;
  final double width;
  final bool foreground;

  @override
  Widget build(BuildContext context) {
    return MascotSpriteFrame(
      atlas: atlas,
      frameName: frameName,
      width: width,
    );
  }
}

class _SceneUiCard extends StatelessWidget {
  const _SceneUiCard({
    required this.size,
    required this.title,
    required this.lines,
  });

  final double size;
  final String title;
  final List<double> lines;

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
          width: size * 0.33,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECAF),
                  borderRadius: BorderRadius.circular(size * 0.07),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: size * 0.04,
                    vertical: size * 0.024,
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: size * 0.042,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E3A78),
                    ),
                  ),
                ),
              ),
              SizedBox(height: size * 0.04),
              for (final widthFactor in lines) ...[
                FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Container(
                    height: size * 0.03,
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
