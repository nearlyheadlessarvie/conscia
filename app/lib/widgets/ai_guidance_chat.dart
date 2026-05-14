import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/assets/mascot_sprite_sheet.dart';
import '../core/theme/app_colors.dart';
import '../services/user_service.dart';

enum AiGuidanceSpeaker { user, devil, angel, conscia }

class AiGuidanceSheetHandle extends StatelessWidget {
  const AiGuidanceSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: colors.border,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class AiGuidanceChatMessage extends StatelessWidget {
  const AiGuidanceChatMessage({
    super.key,
    required this.speaker,
    required this.message,
    this.badgeLabel,
    this.userProfile,
    this.keyPrefix = 'guidance',
  });

  final AiGuidanceSpeaker speaker;
  final String message;
  final String? badgeLabel;
  final UserProfile? userProfile;
  final String keyPrefix;

  bool get _isRightAligned => speaker != AiGuidanceSpeaker.devil;

  String get _keyName => switch (speaker) {
        AiGuidanceSpeaker.user => 'user',
        AiGuidanceSpeaker.devil => 'devil',
        AiGuidanceSpeaker.angel => 'angel',
        AiGuidanceSpeaker.conscia => 'conscia',
      };

  String get _label => switch (speaker) {
        AiGuidanceSpeaker.user => 'You',
        AiGuidanceSpeaker.devil => 'Devil',
        AiGuidanceSpeaker.angel => 'Angel',
        AiGuidanceSpeaker.conscia => 'Conscia',
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width - 40;
    const avatarSize = 42.0;
    const bubbleGap = 10.0;

    final accent = switch (speaker) {
      AiGuidanceSpeaker.user => Colors.white,
      AiGuidanceSpeaker.devil => colors.devilAccent,
      AiGuidanceSpeaker.angel => colors.angelAccent,
      AiGuidanceSpeaker.conscia => colors.deepNavy,
    };
    final borderColor = switch (speaker) {
      AiGuidanceSpeaker.user => colors.deepNavy,
      AiGuidanceSpeaker.devil => colors.devilAccent.withValues(alpha: 0.28),
      AiGuidanceSpeaker.angel => colors.angelAccent.withValues(alpha: 0.28),
      AiGuidanceSpeaker.conscia => colors.border,
    };
    final backgroundColor = switch (speaker) {
      AiGuidanceSpeaker.user => colors.deepNavy,
      AiGuidanceSpeaker.devil => colors.devilSoft,
      AiGuidanceSpeaker.angel => colors.angelSoft,
      AiGuidanceSpeaker.conscia => null,
    };
    final messageColor =
        speaker == AiGuidanceSpeaker.user ? Colors.white : colors.ink;
    final gradient = speaker == AiGuidanceSpeaker.conscia
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.surfaceRaised,
              colors.navySoft.withValues(alpha: 0.52),
            ],
          )
        : null;

    return Align(
      alignment: _isRightAligned ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: _isRightAligned ? 0 : avatarSize + bubbleGap,
                right: _isRightAligned ? avatarSize + bubbleGap : 0,
                bottom: 18,
              ),
              child: Container(
                key: ValueKey('$keyPrefix-$_keyName-message'),
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  gradient: gradient,
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label,
                      style: textTheme.labelSmall?.copyWith(
                        color: speaker == AiGuidanceSpeaker.user
                            ? Colors.white.withValues(alpha: 0.82)
                            : accent,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: messageColor,
                        height: 1.42,
                      ),
                    ),
                    if (badgeLabel != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: colors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            child: Text(
                              badgeLabel!,
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.deepNavy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Positioned(
              left: _isRightAligned ? null : 0,
              right: _isRightAligned ? 0 : null,
              bottom: 0,
              child: _AiGuidanceSpeakerAvatar(
                speaker: speaker,
                userProfile: userProfile,
                keyPrefix: keyPrefix,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiGuidanceSpeakerAvatar extends StatelessWidget {
  const _AiGuidanceSpeakerAvatar({
    required this.speaker,
    required this.keyPrefix,
    this.userProfile,
  });

  final AiGuidanceSpeaker speaker;
  final String keyPrefix;
  final UserProfile? userProfile;

  String get _keyName => switch (speaker) {
        AiGuidanceSpeaker.user => 'user',
        AiGuidanceSpeaker.devil => 'devil',
        AiGuidanceSpeaker.angel => 'angel',
        AiGuidanceSpeaker.conscia => 'conscia',
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Container(
      key: ValueKey('$keyPrefix-$_keyName-avatar'),
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceRaised,
        border: Border.all(color: colors.border),
      ),
      child: ClipOval(
        child: switch (speaker) {
          AiGuidanceSpeaker.user => _UserGuidanceAvatar(profile: userProfile),
          AiGuidanceSpeaker.devil => const _ProfileMascotSprite(
              profileAtlas: devilProfileSpriteAtlas,
              fallbackAtlas: devilMascotAtlas,
            ),
          AiGuidanceSpeaker.angel => const _ProfileMascotSprite(
              profileAtlas: angelProfileSpriteAtlas,
              fallbackAtlas: angelMascotAtlas,
            ),
          AiGuidanceSpeaker.conscia => Padding(
              padding: const EdgeInsets.all(5),
              child: SvgPicture.asset(
                'assets/images/app_icon.svg',
                key: ValueKey('$keyPrefix-conscia-app-icon'),
                width: 26,
                height: 26,
              ),
            ),
        },
      ),
    );
  }
}

class _ProfileMascotSprite extends StatefulWidget {
  const _ProfileMascotSprite({
    required this.profileAtlas,
    required this.fallbackAtlas,
  });

  final MascotSpriteAtlas profileAtlas;
  final MascotSpriteAtlas fallbackAtlas;

  @override
  State<_ProfileMascotSprite> createState() => _ProfileMascotSpriteState();
}

class _ProfileMascotSpriteState extends State<_ProfileMascotSprite> {
  late final Future<bool> _profileAssetAvailable = rootBundle
      .load(widget.profileAtlas.assetPath)
      .then((_) => true)
      .catchError((_) => false);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _profileAssetAvailable,
      builder: (context, snapshot) {
        final useProfile = snapshot.data == true;
        return MascotSpriteFrame(
          atlas: useProfile ? widget.profileAtlas : widget.fallbackAtlas,
          frameName: '1_neutral.png',
          width: 36,
        );
      },
    );
  }
}

class _UserGuidanceAvatar extends StatelessWidget {
  const _UserGuidanceAvatar({required this.profile});

  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final photoUrl = profile?.photoUrl?.trim();
    final initials = _initialsForProfile(profile);

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return Image.network(
        photoUrl,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _InitialsAvatar(initials: initials),
      );
    }

    return _InitialsAvatar(initials: initials, color: colors.deepNavy);
  }

  String _initialsForProfile(UserProfile? profile) {
    final name = profile?.displayName?.trim();
    final source =
        name != null && name.isNotEmpty ? name : profile?.email.trim() ?? 'You';
    final parts = source
        .split(RegExp(r'[\s@._-]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Y';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts[0].characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.initials,
    this.color,
  });

  final String initials;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return ColoredBox(
      color: color ?? colors.deepNavy,
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}
