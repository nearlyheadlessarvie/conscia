import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CategoryIcons {
  CategoryIcons._();

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static final Map<String, _CategorySpec> _specs = {
    'Groceries': const _CategorySpec(
      material: Icons.shopping_cart_rounded,
      cupertino: CupertinoIcons.cart_fill,
      accent: Color(0xFF2E7D5B),
      tint: Color(0xFFE4F5EA),
    ),
    'Dining': const _CategorySpec(
      material: Icons.restaurant_rounded,
      cupertino: CupertinoIcons.tuningfork,
      accent: Color(0xFF233A8B),
      tint: Color(0xFFE8EDFF),
    ),
    'Transport': const _CategorySpec(
      material: Icons.directions_car_filled_rounded,
      cupertino: CupertinoIcons.car_detailed,
      accent: Color(0xFF3B4C68),
      tint: Color(0xFFE9EEF5),
    ),
    'Gaming': const _CategorySpec(
      material: Icons.sports_esports_rounded,
      cupertino: CupertinoIcons.game_controller_solid,
      accent: Color(0xFF5A36A8),
      tint: Color(0xFFF0EAFF),
    ),
    'Entertainment': const _CategorySpec(
      material: Icons.movie_creation_rounded,
      cupertino: CupertinoIcons.ticket_fill,
      accent: Color(0xFF8A3F7A),
      tint: Color(0xFFF9EAF5),
    ),
    'Shopping': const _CategorySpec(
      material: Icons.shopping_bag_rounded,
      cupertino: CupertinoIcons.bag_fill,
      accent: Color(0xFF204AA5),
      tint: Color(0xFFE6EEFF),
    ),
    'Health': const _CategorySpec(
      material: Icons.favorite_rounded,
      cupertino: CupertinoIcons.heart_fill,
      accent: Color(0xFFD14A55),
      tint: Color(0xFFFFEBEE),
    ),
    'Bills': const _CategorySpec(
      material: Icons.receipt_long_rounded,
      cupertino: CupertinoIcons.doc_text_fill,
      accent: Color(0xFF4E5E7D),
      tint: Color(0xFFF0F3F9),
    ),
    'Education': const _CategorySpec(
      material: Icons.school_rounded,
      cupertino: CupertinoIcons.book_fill,
      accent: Color(0xFF3A6D9A),
      tint: Color(0xFFE8F4FF),
    ),
    'Travel': const _CategorySpec(
      material: Icons.flight_takeoff_rounded,
      cupertino: CupertinoIcons.airplane,
      accent: Color(0xFF0D7B84),
      tint: Color(0xFFE4F7F8),
    ),
    'Coffee': const _CategorySpec(
      material: Icons.coffee_rounded,
      cupertino: Icons.coffee_rounded,
      accent: Color(0xFF7B4B2A),
      tint: Color(0xFFF7EBDD),
    ),
    'Subscriptions': const _CategorySpec(
      material: Icons.autorenew_rounded,
      cupertino: CupertinoIcons.arrow_2_circlepath_circle_fill,
      accent: Color(0xFF4064B2),
      tint: Color(0xFFEAF0FF),
    ),
    'Salary': const _CategorySpec(
      material: Icons.account_balance_rounded,
      cupertino: CupertinoIcons.money_dollar_circle_fill,
      accent: Color(0xFF2D7A66),
      tint: Color(0xFFE5F7F1),
    ),
    'Freelance': const _CategorySpec(
      material: Icons.work_rounded,
      cupertino: CupertinoIcons.briefcase_fill,
      accent: Color(0xFF9A5F29),
      tint: Color(0xFFFBEFDF),
    ),
    'Business': const _CategorySpec(
      material: Icons.storefront_rounded,
      cupertino: CupertinoIcons.bag_badge_plus,
      accent: Color(0xFF6F4DA1),
      tint: Color(0xFFF2EAFF),
    ),
    'Investment': const _CategorySpec(
      material: Icons.trending_up_rounded,
      cupertino: CupertinoIcons.chart_bar_alt_fill,
      accent: Color(0xFF2C8E5A),
      tint: Color(0xFFE7F8EC),
    ),
    'Rental Income': const _CategorySpec(
      material: Icons.home_work_rounded,
      cupertino: CupertinoIcons.house_fill,
      accent: Color(0xFF397089),
      tint: Color(0xFFE7F3F8),
    ),
    'Bonus': const _CategorySpec(
      material: Icons.workspace_premium_rounded,
      cupertino: CupertinoIcons.star_fill,
      accent: Color(0xFFBE8B14),
      tint: Color(0xFFFFF5D8),
    ),
    'Gift': const _CategorySpec(
      material: Icons.card_giftcard_rounded,
      cupertino: CupertinoIcons.gift_fill,
      accent: Color(0xFFBE4F8A),
      tint: Color(0xFFFFE8F4),
    ),
    'Other': const _CategorySpec(
      material: Icons.more_horiz_rounded,
      cupertino: CupertinoIcons.ellipsis_circle_fill,
      accent: Color(0xFF667085),
      tint: Color(0xFFF3F4F6),
    ),
  };

  static IconData forCategory(String category) => _spec(category).icon(_isIOS);

  static _CategorySpec _spec(String category) =>
      _specs[category] ?? _specs['Other']!;

  static Widget badge(
    String category, {
    double size = 20,
    bool filled = true,
    bool selected = false,
  }) {
    return _CategoryBadge(
      spec: _spec(category),
      size: size,
      filled: filled,
      selected: selected,
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.spec,
    required this.size,
    required this.filled,
    required this.selected,
  });

  final _CategorySpec spec;
  final double size;
  final bool filled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final icon = spec.icon(CategoryIcons._isIOS);
    final bg =
        filled ? spec.tint : spec.tint.withValues(alpha: selected ? 0.9 : 0.55);
    final fg = selected ? spec.accent.withValues(alpha: 0.96) : spec.accent;

    return Container(
      width: size + 12,
      height: size + 12,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          CategoryIcons._isIOS ? (size * 0.48) : (size * 0.42),
        ),
        border: Border.all(
          color: selected
              ? spec.accent.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
      ),
      child: Icon(
        icon,
        size: size,
        color: fg,
      ),
    );
  }
}

class _CategorySpec {
  const _CategorySpec({
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
