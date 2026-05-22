import 'package:flutter/material.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import '../../widgets/conscia_glyph.dart';

enum AppIconKey {
  home,
  homeActive,
  transactions,
  transactionsActive,
  receipt,
  scan,
  assistant,
  assistantActive,
  settings,
  settingsActive,
  add,
  close,
  check,
  chevronLeft,
  chevronRight,
  calendar,
  person,
  family,
  people,
  search,
  premium,
  premiumMedal,
  lock,
  password,
  refresh,
  recurring,
  warning,
  error,
  help,
  edit,
  delete,
  archive,
  label,
  camera,
  ai,
  aiReflect,
  payments,
  logout,
  language,
  currency,
  location,
  download,
  fingerprint,
  star,
  admin,
  email,
  visibility,
  visibilityOff,
  thumbsUp,
  thumbsDown,
  arrowDown,
  arrowUp,
  wallet,
  merchant,
  flag,
  notifications,
  achievement,
  fire,
  questPending,
  insightTrend,
  pieChart,
  brain,
  mic,
  micOff,
  more,
  appleBrand,
  passkey,
  serviceApi,
  serviceDatabase,
  serviceStorage,
  serviceAi,
  serviceHealth,
  sessionExpired,
  offlineDevice,
  offlineCloud,
  familyInvite,
  household,
  ownerAccess,
  privacyBoundary,
  merchantSuggestion,
  info,
  verified,
  code,
  photoLibrary,
  receiptScan,
  walletOutline,
  sparkleGuidance,
  sprout,
  timer,
  tune,
  lockClock,
  spendingStyleSaver,
  spendingStyleBalanced,
  spendingStyleFlexible,
  occupationEmployed,
  occupationSelfEmployed,
  occupationStudent,
  occupationRetired,
  householdSolo,
  householdCouple,
  householdFamily,
  sharedHousehold,
}

abstract class AppIcons {
  static Widget icon(
    AppIconKey key, {
    required Color color,
    double size = 20,
    double? strokeWidth,
    Key? keyId,
  }) {
    final resolvedSize = size * _visualScaleFor(key);
    return ConsciaGlyph.raw(
      key: keyId,
      icon: _hugeIconFor(key),
      color: color,
      size: resolvedSize,
      strokeWidth: strokeWidth,
    );
  }

  static double _visualScaleFor(AppIconKey key) {
    return switch (key) {
      AppIconKey.settings ||
      AppIconKey.settingsActive ||
      AppIconKey.notifications => 0.86,
      _ => 1,
    };
  }

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

  static _ProfileIconSpec _spendingStyleSpec(String value) => switch (value) {
        'saver' => const _ProfileIconSpec(
            key: AppIconKey.spendingStyleSaver,
            accent: Color(0xFF87621F),
            tint: Color(0xFFFFF1C7),
          ),
        'free_spender' => const _ProfileIconSpec(
            key: AppIconKey.spendingStyleFlexible,
            accent: Color(0xFF9F4A18),
            tint: Color(0xFFFFE7D9),
          ),
        _ => const _ProfileIconSpec(
            key: AppIconKey.spendingStyleBalanced,
            accent: Color(0xFF233A8B),
            tint: Color(0xFFE7ECFF),
          ),
      };

  static _ProfileIconSpec _profileSpec(String value) => switch (value) {
        'employed' => const _ProfileIconSpec(
            key: AppIconKey.occupationEmployed,
            accent: Color(0xFF243B8A),
            tint: Color(0xFFE7ECFF),
          ),
        'self_employed' => const _ProfileIconSpec(
            key: AppIconKey.occupationSelfEmployed,
            accent: Color(0xFF3254A0),
            tint: Color(0xFFEAF0FF),
          ),
        'student' => const _ProfileIconSpec(
            key: AppIconKey.occupationStudent,
            accent: Color(0xFF2D4AA5),
            tint: Color(0xFFE8EDFF),
          ),
        'retired' => const _ProfileIconSpec(
            key: AppIconKey.occupationRetired,
            accent: Color(0xFF3753A6),
            tint: Color(0xFFEAF0FF),
          ),
        'solo' => const _ProfileIconSpec(
            key: AppIconKey.householdSolo,
            accent: Color(0xFF243B8A),
            tint: Color(0xFFEAF0FF),
          ),
        'couple' => const _ProfileIconSpec(
            key: AppIconKey.householdCouple,
            accent: Color(0xFF2E3EA1),
            tint: Color(0xFFECEFff),
          ),
        'family' => const _ProfileIconSpec(
            key: AppIconKey.householdFamily,
            accent: Color(0xFF35509C),
            tint: Color(0xFFEAF0FF),
          ),
        'shared' => const _ProfileIconSpec(
            key: AppIconKey.sharedHousehold,
            accent: Color(0xFF2A3F93),
            tint: Color(0xFFE8EDFF),
          ),
        _ => const _ProfileIconSpec(
            key: AppIconKey.more,
            accent: Color(0xFF53627D),
            tint: Color(0xFFF1F4FA),
          ),
      };
}

List<List<dynamic>> _hugeIconFor(AppIconKey key) {
  return switch (key) {
    AppIconKey.home || AppIconKey.homeActive => HugeIconsStrokeRounded.home07,
    AppIconKey.transactions ||
    AppIconKey.transactionsActive =>
      HugeIconsStrokeRounded.invoice01,
    AppIconKey.receipt => HugeIconsStrokeRounded.invoice01,
    AppIconKey.scan => HugeIconsStrokeRounded.scan,
    AppIconKey.assistant ||
    AppIconKey.assistantActive =>
      HugeIconsStrokeRounded.artificialIntelligence08,
    AppIconKey.settings ||
    AppIconKey.settingsActive =>
      HugeIconsStrokeRounded.settings03,
    AppIconKey.add => HugeIconsStrokeRounded.plusSign,
    AppIconKey.close => HugeIconsStrokeRounded.cancel01,
    AppIconKey.check => HugeIconsStrokeRounded.checkmarkCircle02,
    AppIconKey.chevronLeft => HugeIconsStrokeRounded.arrowLeft01,
    AppIconKey.chevronRight => HugeIconsStrokeRounded.arrowRight01,
    AppIconKey.calendar => HugeIconsStrokeRounded.calendar03,
    AppIconKey.person => HugeIconsStrokeRounded.user,
    AppIconKey.family => HugeIconsStrokeRounded.userGroup,
    AppIconKey.people => HugeIconsStrokeRounded.userGroup,
    AppIconKey.search => HugeIconsStrokeRounded.search01,
    AppIconKey.premium => HugeIconsStrokeRounded.star,
    AppIconKey.premiumMedal => HugeIconsStrokeRounded.medal02,
    AppIconKey.lock => HugeIconsStrokeRounded.lock,
    AppIconKey.password => HugeIconsStrokeRounded.squareLockPassword,
    AppIconKey.refresh => HugeIconsStrokeRounded.refresh,
    AppIconKey.recurring => HugeIconsStrokeRounded.repeat,
    AppIconKey.warning => HugeIconsStrokeRounded.alertCircle,
    AppIconKey.error => HugeIconsStrokeRounded.alert02,
    AppIconKey.help => HugeIconsStrokeRounded.helpCircle,
    AppIconKey.edit => HugeIconsStrokeRounded.pencilEdit02,
    AppIconKey.delete => HugeIconsStrokeRounded.delete02,
    AppIconKey.archive => HugeIconsStrokeRounded.archive,
    AppIconKey.label => HugeIconsStrokeRounded.label,
    AppIconKey.camera => HugeIconsStrokeRounded.camera01,
    AppIconKey.ai => HugeIconsStrokeRounded.artificialIntelligence08,
    AppIconKey.aiReflect =>
      HugeIconsStrokeRounded.aiContentGenerator01,
    AppIconKey.payments => HugeIconsStrokeRounded.payment02,
    AppIconKey.logout => HugeIconsStrokeRounded.logout01,
    AppIconKey.language => HugeIconsStrokeRounded.languageCircle,
    AppIconKey.currency => HugeIconsStrokeRounded.exchangeDollar,
    AppIconKey.location => HugeIconsStrokeRounded.location02,
    AppIconKey.download => HugeIconsStrokeRounded.download02,
    AppIconKey.fingerprint => HugeIconsStrokeRounded.fingerprintScan,
    AppIconKey.star => HugeIconsStrokeRounded.star,
    AppIconKey.admin => HugeIconsStrokeRounded.shieldUser,
    AppIconKey.email => HugeIconsStrokeRounded.mailAtSign01,
    AppIconKey.visibility => HugeIconsStrokeRounded.view,
    AppIconKey.visibilityOff => HugeIconsStrokeRounded.viewOff,
    AppIconKey.thumbsUp => HugeIconsStrokeRounded.thumbsUp,
    AppIconKey.thumbsDown => HugeIconsStrokeRounded.thumbsDown,
    AppIconKey.arrowDown => HugeIconsStrokeRounded.arrowDown01,
    AppIconKey.arrowUp => HugeIconsStrokeRounded.arrowUp01,
    AppIconKey.wallet => HugeIconsStrokeRounded.wallet01,
    AppIconKey.merchant => HugeIconsStrokeRounded.store01,
    AppIconKey.flag => HugeIconsStrokeRounded.flag02,
    AppIconKey.notifications => HugeIconsStrokeRounded.notification01,
    AppIconKey.achievement => HugeIconsStrokeRounded.award01,
    AppIconKey.fire => HugeIconsStrokeRounded.fire02,
    AppIconKey.questPending => HugeIconsStrokeRounded.radio01,
    AppIconKey.insightTrend => HugeIconsStrokeRounded.chartBarLine,
    AppIconKey.pieChart => HugeIconsStrokeRounded.pieChart,
    AppIconKey.brain =>
      HugeIconsStrokeRounded.artificialIntelligence04,
    AppIconKey.mic => HugeIconsStrokeRounded.mic01,
    AppIconKey.micOff => HugeIconsStrokeRounded.stopCircle,
    AppIconKey.more => HugeIconsStrokeRounded.moreHorizontalCircle01,
    AppIconKey.appleBrand => HugeIconsStrokeRounded.apple,
    AppIconKey.passkey => HugeIconsStrokeRounded.fingerprintScan,
    AppIconKey.serviceApi => HugeIconsStrokeRounded.cloudServer,
    AppIconKey.serviceDatabase => HugeIconsStrokeRounded.database,
    AppIconKey.serviceStorage => HugeIconsStrokeRounded.hardDrive,
    AppIconKey.serviceAi =>
      HugeIconsStrokeRounded.artificialIntelligence04,
    AppIconKey.serviceHealth => HugeIconsStrokeRounded.toolbox,
    AppIconKey.sessionExpired => HugeIconsStrokeRounded.clockAlert,
    AppIconKey.offlineDevice => HugeIconsStrokeRounded.cloudOff,
    AppIconKey.offlineCloud => HugeIconsStrokeRounded.cloudOff,
    AppIconKey.familyInvite => HugeIconsStrokeRounded.userAdd02,
    AppIconKey.household => HugeIconsStrokeRounded.home07,
    AppIconKey.ownerAccess => HugeIconsStrokeRounded.shieldUser,
    AppIconKey.privacyBoundary => HugeIconsStrokeRounded.lock,
    AppIconKey.merchantSuggestion => HugeIconsStrokeRounded.storeLocation01,
    AppIconKey.info => HugeIconsStrokeRounded.informationCircle,
    AppIconKey.verified => HugeIconsStrokeRounded.checkmarkBadge02,
    AppIconKey.code => HugeIconsStrokeRounded.code,
    AppIconKey.photoLibrary => HugeIconsStrokeRounded.image01,
    AppIconKey.receiptScan => HugeIconsStrokeRounded.scan,
    AppIconKey.walletOutline => HugeIconsStrokeRounded.wallet02,
    AppIconKey.sparkleGuidance => HugeIconsStrokeRounded.sparkles,
    AppIconKey.sprout => HugeIconsStrokeRounded.plant01,
    AppIconKey.timer => HugeIconsStrokeRounded.timer02,
    AppIconKey.tune => HugeIconsStrokeRounded.slidersHorizontal,
    AppIconKey.lockClock => HugeIconsStrokeRounded.clockAlert,
    AppIconKey.spendingStyleSaver => HugeIconsStrokeRounded.moneySavingJar,
    AppIconKey.spendingStyleBalanced => HugeIconsStrokeRounded.targetDollar,
    AppIconKey.spendingStyleFlexible => HugeIconsStrokeRounded.sparkles,
    AppIconKey.occupationEmployed => HugeIconsStrokeRounded.briefcase02,
    AppIconKey.occupationSelfEmployed => HugeIconsStrokeRounded.laptop,
    AppIconKey.occupationStudent => HugeIconsStrokeRounded.book01,
    AppIconKey.occupationRetired => HugeIconsStrokeRounded.sun03,
    AppIconKey.householdSolo => HugeIconsStrokeRounded.user,
    AppIconKey.householdCouple => HugeIconsStrokeRounded.userMultiple02,
    AppIconKey.householdFamily => HugeIconsStrokeRounded.userGroup,
    AppIconKey.sharedHousehold => HugeIconsStrokeRounded.home07,
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
          size * 0.38,
        ),
        border: Border.all(
          color: selected
              ? spec.accent.withValues(alpha: 0.16)
              : Colors.transparent,
        ),
      ),
      child: Center(
        child: AppIcons.icon(
          spec.key,
          color: fg,
          size: size,
        ),
      ),
    );
  }
}

class _ProfileIconSpec {
  const _ProfileIconSpec({
    required this.key,
    required this.accent,
    required this.tint,
  });

  final AppIconKey key;
  final Color accent;
  final Color tint;
}
