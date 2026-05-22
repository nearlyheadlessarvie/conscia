import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hugeicons/styles/stroke_rounded.dart';

import 'conscia_glyph_kind.dart';
import 'conscia_glyph_mapper.dart';

class ConsciaGlyph extends StatelessWidget {
  const ConsciaGlyph({
    super.key,
    required ConsciaGlyphKind this.kind,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  }) : icon = null;

  const ConsciaGlyph.raw({
    super.key,
    required this.icon,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  }) : kind = null;

  ConsciaGlyph.category(
    String category, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  })  : kind = ConsciaGlyphMapper.category(category),
        icon = null;

  ConsciaGlyph.quest(
    String questKey, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  })  : kind = ConsciaGlyphMapper.quest(questKey),
        icon = null;

  ConsciaGlyph.milestone(
    String badgeKey, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
    bool unlocked = true,
  })  : kind = unlocked
            ? ConsciaGlyphMapper.milestone(badgeKey)
            : ConsciaGlyphKind.lock,
        icon = null;

  ConsciaGlyph.level(
    String levelKey, {
    super.key,
    required this.color,
    this.size = 22,
    this.strokeWidth,
  })  : kind = ConsciaGlyphMapper.level(levelKey),
        icon = null;

  final ConsciaGlyphKind? kind;
  final List<List<dynamic>>? icon;
  final Color color;
  final double size;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: HugeIcon(
        icon: icon ?? _hugeIconFor(kind!),
        color: color,
        size: size,
        strokeWidth: strokeWidth ?? (size * 0.1).clamp(1.6, 2.2),
      ),
    );
  }
}

List<List<dynamic>> _hugeIconFor(ConsciaGlyphKind kind) {
  return switch (kind) {
    ConsciaGlyphKind.dining => HugeIconsStrokeRounded.restaurant,
    ConsciaGlyphKind.groceries => HugeIconsStrokeRounded.shoppingCart01,
    ConsciaGlyphKind.transport => HugeIconsStrokeRounded.car01,
    ConsciaGlyphKind.entertainment => HugeIconsStrokeRounded.playCircle,
    ConsciaGlyphKind.gaming => HugeIconsStrokeRounded.gameController01,
    ConsciaGlyphKind.shopping => HugeIconsStrokeRounded.shoppingBag01,
    ConsciaGlyphKind.health => HugeIconsStrokeRounded.heartAdd,
    ConsciaGlyphKind.bills => HugeIconsStrokeRounded.invoice01,
    ConsciaGlyphKind.education => HugeIconsStrokeRounded.book01,
    ConsciaGlyphKind.travel => HugeIconsStrokeRounded.airplaneTakeOff01,
    ConsciaGlyphKind.coffee => HugeIconsStrokeRounded.coffee02,
    ConsciaGlyphKind.subscription => HugeIconsStrokeRounded.refresh,
    ConsciaGlyphKind.income => HugeIconsStrokeRounded.moneyReceiveCircle,
    ConsciaGlyphKind.salary => HugeIconsStrokeRounded.bank,
    ConsciaGlyphKind.freelance => HugeIconsStrokeRounded.briefcase01,
    ConsciaGlyphKind.business => HugeIconsStrokeRounded.store01,
    ConsciaGlyphKind.investment => HugeIconsStrokeRounded.chartUp,
    ConsciaGlyphKind.rentalIncome => HugeIconsStrokeRounded.house01,
    ConsciaGlyphKind.bonus => HugeIconsStrokeRounded.badge,
    ConsciaGlyphKind.wallet => HugeIconsStrokeRounded.wallet01,
    ConsciaGlyphKind.card => HugeIconsStrokeRounded.creditCard,
    ConsciaGlyphKind.cash => HugeIconsStrokeRounded.money03,
    ConsciaGlyphKind.bank => HugeIconsStrokeRounded.bank,
    ConsciaGlyphKind.transfer =>
      HugeIconsStrokeRounded.arrowDataTransferHorizontal,
    ConsciaGlyphKind.refund => HugeIconsStrokeRounded.moneyReceiveSquare,
    ConsciaGlyphKind.fee => HugeIconsStrokeRounded.invoice02,
    ConsciaGlyphKind.debt => HugeIconsStrokeRounded.creditCardPos,
    ConsciaGlyphKind.savings => HugeIconsStrokeRounded.moneySavingJar,
    ConsciaGlyphKind.receipt => HugeIconsStrokeRounded.receiptText,
    ConsciaGlyphKind.home => HugeIconsStrokeRounded.house03,
    ConsciaGlyphKind.gift => HugeIconsStrokeRounded.gift,
    ConsciaGlyphKind.calendar => HugeIconsStrokeRounded.calendar03,
    ConsciaGlyphKind.alert => HugeIconsStrokeRounded.alertCircle,
    ConsciaGlyphKind.check => HugeIconsStrokeRounded.checkmarkCircle02,
    ConsciaGlyphKind.more => HugeIconsStrokeRounded.moreHorizontalCircle01,
    ConsciaGlyphKind.trail => HugeIconsStrokeRounded.route01,
    ConsciaGlyphKind.reflect => HugeIconsStrokeRounded.notebook02,
    ConsciaGlyphKind.pause => HugeIconsStrokeRounded.pauseCircle,
    ConsciaGlyphKind.insight => HugeIconsStrokeRounded.chartBarLine,
    ConsciaGlyphKind.signal => HugeIconsStrokeRounded.alert02,
    ConsciaGlyphKind.shield => HugeIconsStrokeRounded.shield01,
    ConsciaGlyphKind.family => HugeIconsStrokeRounded.userGroup,
    ConsciaGlyphKind.recurring => HugeIconsStrokeRounded.refresh,
    ConsciaGlyphKind.trophy => HugeIconsStrokeRounded.award01,
    ConsciaGlyphKind.lock => HugeIconsStrokeRounded.lock,
    ConsciaGlyphKind.sprout => HugeIconsStrokeRounded.plant01,
    ConsciaGlyphKind.compass => HugeIconsStrokeRounded.compass,
    ConsciaGlyphKind.crown => HugeIconsStrokeRounded.crown,
    ConsciaGlyphKind.monk => HugeIconsStrokeRounded.leaf01,
    ConsciaGlyphKind.work => HugeIconsStrokeRounded.briefcase02,
  };
}
