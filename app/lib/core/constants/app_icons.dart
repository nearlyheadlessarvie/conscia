import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class AppIcons {
  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static IconData adaptive({
    required IconData material,
    required IconData cupertino,
  }) =>
      _isIOS ? cupertino : material;

  static IconData get home =>
      adaptive(material: Icons.home_outlined, cupertino: CupertinoIcons.house);
  static IconData get homeActive =>
      adaptive(material: Icons.home, cupertino: CupertinoIcons.house_fill);
  static IconData get transactions => adaptive(
        material: Icons.receipt_long_outlined,
        cupertino: CupertinoIcons.list_bullet,
      );
  static IconData get transactionsActive => adaptive(
        material: Icons.receipt_long,
        cupertino: CupertinoIcons.list_bullet,
      );
  static IconData get scan => adaptive(
        material: Icons.document_scanner_outlined,
        cupertino: CupertinoIcons.camera_viewfinder,
      );
  static IconData get assistant => adaptive(
        material: Icons.auto_awesome_outlined,
        cupertino: CupertinoIcons.sparkles,
      );
  static IconData get assistantActive =>
      adaptive(material: Icons.auto_awesome, cupertino: CupertinoIcons.sparkles);
  static IconData get settings => adaptive(
        material: Icons.settings_outlined,
        cupertino: CupertinoIcons.settings,
      );
  static IconData get settingsActive => adaptive(
        material: Icons.settings,
        cupertino: CupertinoIcons.settings_solid,
      );

  static IconData get add =>
      adaptive(material: Icons.add, cupertino: CupertinoIcons.add);
  static IconData get close =>
      adaptive(material: Icons.close, cupertino: CupertinoIcons.xmark);
  static IconData get check =>
      adaptive(material: Icons.check, cupertino: CupertinoIcons.checkmark);
  static IconData get chevronRight => adaptive(
        material: Icons.chevron_right,
        cupertino: CupertinoIcons.chevron_right,
      );
  static IconData get calendar => adaptive(
        material: Icons.calendar_today,
        cupertino: CupertinoIcons.calendar,
      );
  static IconData get person =>
      adaptive(material: Icons.person, cupertino: CupertinoIcons.person);

  static IconData get saver => adaptive(
        material: Icons.savings,
        cupertino: CupertinoIcons.money_dollar_circle,
      );
  static IconData get balanced => adaptive(
        material: Icons.balance,
        cupertino: CupertinoIcons.equal_circle,
      );
  static IconData get freeSpender =>
      adaptive(material: Icons.celebration, cupertino: CupertinoIcons.star);
  static IconData get employed => adaptive(
        material: Icons.work,
        cupertino: CupertinoIcons.briefcase,
      );
  static IconData get selfEmployed => adaptive(
        material: Icons.laptop,
        cupertino: CupertinoIcons.device_laptop,
      );
  static IconData get student => adaptive(
        material: Icons.school,
        cupertino: CupertinoIcons.book,
      );
  static IconData get retired => adaptive(
        material: Icons.beach_access,
        cupertino: CupertinoIcons.sun_max,
      );
  static IconData get other => adaptive(
        material: Icons.more_horiz,
        cupertino: CupertinoIcons.ellipsis,
      );
  static IconData get couple => adaptive(
        material: Icons.people,
        cupertino: CupertinoIcons.person_2,
      );
  static IconData get family => adaptive(
        material: Icons.family_restroom,
        cupertino: CupertinoIcons.person_3,
      );
  static IconData get sharedHome =>
      adaptive(material: Icons.home, cupertino: CupertinoIcons.house);

  static Widget spendingStyleBadge(
    String value, {
    double size = 26,
    bool selected = false,
  }) {
    return _ProfileBadge(
      spec: _spendingStyleSpec(value),
      size: size,
      selected: selected,
      emphasis: 1,
    );
  }

  static Widget profileBadge(
    String value, {
    double size = 18,
    bool selected = false,
  }) {
    return _ProfileBadge(
      spec: _profileSpec(value),
      size: size,
      selected: selected,
      emphasis: 0,
    );
  }

  static _ProfileIconSpec _spendingStyleSpec(String value) =>
      switch (value) {
        'saver' => const _ProfileIconSpec(
            material: Icons.savings_rounded,
            cupertino: CupertinoIcons.money_dollar_circle_fill,
            accent: Color(0xFF87621F),
            tint: Color(0xFFFFF1C7),
          ),
        'free_spender' => const _ProfileIconSpec(
            material: Icons.celebration_rounded,
            cupertino: CupertinoIcons.sparkles,
            accent: Color(0xFF9F4A18),
            tint: Color(0xFFFFE7D9),
          ),
        _ => const _ProfileIconSpec(
            material: Icons.balance_rounded,
            cupertino: CupertinoIcons.equal_circle_fill,
            accent: Color(0xFF233A8B),
            tint: Color(0xFFE7ECFF),
          ),
      };

  static _ProfileIconSpec _profileSpec(String value) => switch (value) {
        'employed' => const _ProfileIconSpec(
            material: Icons.work_rounded,
            cupertino: CupertinoIcons.briefcase_fill,
            accent: Color(0xFF243B8A),
            tint: Color(0xFFE7ECFF),
          ),
        'self_employed' => const _ProfileIconSpec(
            material: Icons.laptop_chromebook_rounded,
            cupertino: CupertinoIcons.device_laptop,
            accent: Color(0xFF3254A0),
            tint: Color(0xFFEAF0FF),
          ),
        'student' => const _ProfileIconSpec(
            material: Icons.school_rounded,
            cupertino: CupertinoIcons.book_fill,
            accent: Color(0xFF2D4AA5),
            tint: Color(0xFFE8EDFF),
          ),
        'retired' => const _ProfileIconSpec(
            material: Icons.beach_access_rounded,
            cupertino: CupertinoIcons.sun_max_fill,
            accent: Color(0xFF3753A6),
            tint: Color(0xFFEAF0FF),
          ),
        'solo' => const _ProfileIconSpec(
            material: Icons.person_rounded,
            cupertino: CupertinoIcons.person_fill,
            accent: Color(0xFF243B8A),
            tint: Color(0xFFEAF0FF),
          ),
        'couple' => const _ProfileIconSpec(
            material: Icons.people_alt_rounded,
            cupertino: CupertinoIcons.person_2_fill,
            accent: Color(0xFF2E3EA1),
            tint: Color(0xFFECEFff),
          ),
        'family' => const _ProfileIconSpec(
            material: Icons.family_restroom_rounded,
            cupertino: CupertinoIcons.person_3_fill,
            accent: Color(0xFF35509C),
            tint: Color(0xFFEAF0FF),
          ),
        'shared' => const _ProfileIconSpec(
            material: Icons.home_rounded,
            cupertino: CupertinoIcons.house_fill,
            accent: Color(0xFF2A3F93),
            tint: Color(0xFFE8EDFF),
          ),
        _ => const _ProfileIconSpec(
            material: Icons.more_horiz_rounded,
            cupertino: CupertinoIcons.ellipsis,
            accent: Color(0xFF53627D),
            tint: Color(0xFFF1F4FA),
          ),
      };
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({
    required this.spec,
    required this.size,
    required this.selected,
    required this.emphasis,
  });

  final _ProfileIconSpec spec;
  final double size;
  final bool selected;
  final int emphasis;

  @override
  Widget build(BuildContext context) {
    final icon = spec.icon(AppIcons._isIOS);
    final bg = selected
        ? spec.tint
        : spec.tint.withValues(alpha: emphasis == 1 ? 0.58 : 0.42);
    final fg = selected
        ? spec.accent
        : spec.accent.withValues(alpha: emphasis == 1 ? 0.92 : 0.86);

    return Container(
      width: size + (emphasis == 1 ? 16 : 12),
      height: size + (emphasis == 1 ? 16 : 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          AppIcons._isIOS ? size * 0.45 : size * 0.38,
        ),
        border: Border.all(
          color: selected
              ? spec.accent.withValues(alpha: 0.16)
              : Colors.transparent,
        ),
      ),
      child: Icon(icon, size: size, color: fg),
    );
  }
}

class _ProfileIconSpec {
  const _ProfileIconSpec({
    required this.material,
    required this.cupertino,
    required this.accent,
    required this.tint,
  });

  final IconData material;
  final IconData cupertino;
  final Color accent;
  final Color tint;

  IconData icon(bool isIOS) => isIOS ? cupertino : material;
}
