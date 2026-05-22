import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../widgets/conscia_glyph.dart';

class CategoryIcons {
  CategoryIcons._();

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static final _slugPattern = RegExp(r'[^a-z0-9]+');

  static const List<CategoryColorOption> colorOptions = [
    CategoryColorOption(
      key: 'green',
      label: 'Green',
      accent: Color(0xFF43A047),
      tint: Color(0xFFE4F5EA),
    ),
    CategoryColorOption(
      key: 'orange',
      label: 'Orange',
      accent: Color(0xFFFF9800),
      tint: Color(0xFFFFF3E0),
    ),
    CategoryColorOption(
      key: 'pink',
      label: 'Pink',
      accent: Color(0xFFEC407A),
      tint: Color(0xFFFFE8F4),
    ),
    CategoryColorOption(
      key: 'blue',
      label: 'Blue',
      accent: Color(0xFF2563EB),
      tint: Color(0xFFE6EEFF),
    ),
    CategoryColorOption(
      key: 'cyan',
      label: 'Cyan',
      accent: Color(0xFF00ACC1),
      tint: Color(0xFFE0F7FA),
    ),
    CategoryColorOption(
      key: 'violet',
      label: 'Violet',
      accent: Color(0xFF7E57C2),
      tint: Color(0xFFF0EAFF),
    ),
    CategoryColorOption(
      key: 'teal',
      label: 'Teal',
      accent: Color(0xFF00838F),
      tint: Color(0xFFE0F7FA),
    ),
    CategoryColorOption(
      key: 'amber',
      label: 'Amber',
      accent: Color(0xFFFFB300),
      tint: Color(0xFFFFF2C8),
    ),
    CategoryColorOption(
      key: 'red',
      label: 'Red',
      accent: Color(0xFFEF4444),
      tint: Color(0xFFFFE5E2),
    ),
    CategoryColorOption(
      key: 'lime',
      label: 'Lime',
      accent: Color(0xFF84CC16),
      tint: Color(0xFFECFCCB),
    ),
    CategoryColorOption(
      key: 'indigo',
      label: 'Indigo',
      accent: Color(0xFF4F46E5),
      tint: Color(0xFFE9EDFF),
    ),
    CategoryColorOption(
      key: 'coral',
      label: 'Coral',
      accent: Color(0xFFFF7043),
      tint: Color(0xFFFFEDE6),
    ),
    CategoryColorOption(
      key: 'mint',
      label: 'Mint',
      accent: Color(0xFF10B981),
      tint: Color(0xFFDFFCF1),
    ),
    CategoryColorOption(
      key: 'plum',
      label: 'Plum',
      accent: Color(0xFFA855F7),
      tint: Color(0xFFF3E8FF),
    ),
    CategoryColorOption(
      key: 'rose',
      label: 'Rose',
      accent: Color(0xFFE11D48),
      tint: Color(0xFFFFE4E6),
    ),
    CategoryColorOption(
      key: 'fuchsia',
      label: 'Fuchsia',
      accent: Color(0xFFC026D3),
      tint: Color(0xFFFAE8FF),
    ),
    CategoryColorOption(
      key: 'sky',
      label: 'Sky',
      accent: Color(0xFF0284C7),
      tint: Color(0xFFE0F2FE),
    ),
    CategoryColorOption(
      key: 'emerald',
      label: 'Emerald',
      accent: Color(0xFF059669),
      tint: Color(0xFFD1FAE5),
    ),
    CategoryColorOption(
      key: 'yellow',
      label: 'Yellow',
      accent: Color(0xFFEAB308),
      tint: Color(0xFFFEF9C3),
    ),
    CategoryColorOption(
      key: 'slate',
      label: 'Slate',
      accent: Color(0xFF475569),
      tint: Color(0xFFE2E8F0),
    ),
    CategoryColorOption(
      key: 'copper',
      label: 'Copper',
      accent: Color(0xFFB45309),
      tint: Color(0xFFFFEDD5),
    ),
    CategoryColorOption(
      key: 'aqua',
      label: 'Aqua',
      accent: Color(0xFF0891B2),
      tint: Color(0xFFCFFAFE),
    ),
  ];

  static const List<CategoryIconOption> iconOptions = trialFontIconOptions;

  static const List<CategoryIconOption> trialFontIconOptions = [
    CategoryIconOption(key: 'groceries', label: 'Groceries'),
    CategoryIconOption(key: 'dining', label: 'Dining'),
    CategoryIconOption(key: 'transport', label: 'Transport'),
    CategoryIconOption(key: 'shopping', label: 'Shopping'),
    CategoryIconOption(key: 'health', label: 'Health'),
    CategoryIconOption(key: 'bills', label: 'Bills'),
    CategoryIconOption(key: 'education', label: 'Education'),
    CategoryIconOption(key: 'travel', label: 'Travel'),
    CategoryIconOption(key: 'coffee', label: 'Coffee'),
    CategoryIconOption(key: 'subscriptions', label: 'Subscriptions'),
    CategoryIconOption(key: 'salary', label: 'Salary'),
    CategoryIconOption(key: 'freelance', label: 'Freelance'),
    CategoryIconOption(key: 'business', label: 'Business'),
    CategoryIconOption(key: 'investment', label: 'Investment'),
    CategoryIconOption(key: 'gift', label: 'Gift'),
    CategoryIconOption(key: 'home', label: 'Home'),
    CategoryIconOption(key: 'utilities', label: 'Utilities'),
    CategoryIconOption(key: 'phone', label: 'Phone'),
    CategoryIconOption(key: 'pets', label: 'Pets'),
    CategoryIconOption(key: 'other', label: 'Other'),
    CategoryIconOption(key: 'gaming', label: 'Gaming'),
    CategoryIconOption(key: 'entertainment', label: 'Entertainment'),
    CategoryIconOption(key: 'rental-income', label: 'Rental income'),
    CategoryIconOption(key: 'bonus', label: 'Bonus'),
    CategoryIconOption(key: 'internet', label: 'Internet'),
    CategoryIconOption(key: 'insurance', label: 'Insurance'),
    CategoryIconOption(key: 'fuel', label: 'Fuel'),
    CategoryIconOption(key: 'parking', label: 'Parking'),
    CategoryIconOption(key: 'repairs', label: 'Repairs'),
    CategoryIconOption(key: 'beauty', label: 'Beauty'),
    CategoryIconOption(key: 'fitness', label: 'Fitness'),
    CategoryIconOption(key: 'charity', label: 'Charity'),
    CategoryIconOption(key: 'books', label: 'Books'),
    CategoryIconOption(key: 'clothing', label: 'Clothing'),
    CategoryIconOption(key: 'taxes', label: 'Taxes'),
    CategoryIconOption(key: 'childcare', label: 'Childcare'),
    CategoryIconOption(key: 'pharmacy', label: 'Pharmacy'),
    CategoryIconOption(key: 'events', label: 'Events'),
    CategoryIconOption(key: 'savings', label: 'Savings'),
    CategoryIconOption(key: 'bank', label: 'Bank'),
  ];

  static final Map<String, _CategorySpec> _specs = {
    'Groceries': const _CategorySpec(
      iconKey: 'groceries',
      material: Icons.shopping_cart_rounded,
      cupertino: CupertinoIcons.cart_fill,
    ),
    'Dining': const _CategorySpec(
      iconKey: 'dining',
      material: Icons.restaurant_rounded,
      cupertino: CupertinoIcons.tuningfork,
    ),
    'Transport': const _CategorySpec(
      iconKey: 'transport',
      material: Icons.directions_car_filled_rounded,
      cupertino: CupertinoIcons.car_detailed,
    ),
    'Gaming': const _CategorySpec(
      iconKey: 'gaming',
      material: Icons.sports_esports_rounded,
      cupertino: CupertinoIcons.game_controller_solid,
    ),
    'Entertainment': const _CategorySpec(
      iconKey: 'entertainment',
      material: Icons.movie_creation_rounded,
      cupertino: CupertinoIcons.ticket_fill,
    ),
    'Shopping': const _CategorySpec(
      iconKey: 'shopping',
      material: Icons.shopping_bag_rounded,
      cupertino: CupertinoIcons.bag_fill,
    ),
    'Health': const _CategorySpec(
      iconKey: 'health',
      material: Icons.favorite_rounded,
      cupertino: CupertinoIcons.heart_fill,
    ),
    'Bills': const _CategorySpec(
      iconKey: 'bills',
      material: Icons.receipt_long_rounded,
      cupertino: CupertinoIcons.doc_text_fill,
    ),
    'Education': const _CategorySpec(
      iconKey: 'education',
      material: Icons.school_rounded,
      cupertino: CupertinoIcons.book_fill,
    ),
    'Travel': const _CategorySpec(
      iconKey: 'travel',
      material: Icons.flight_takeoff_rounded,
      cupertino: CupertinoIcons.airplane,
    ),
    'Coffee': const _CategorySpec(
      iconKey: 'coffee',
      material: Icons.coffee_rounded,
      cupertino: CupertinoIcons.drop_fill,
    ),
    'Subscriptions': const _CategorySpec(
      iconKey: 'subscriptions',
      material: Icons.autorenew_rounded,
      cupertino: CupertinoIcons.arrow_2_circlepath_circle_fill,
    ),
    'Salary': const _CategorySpec(
      iconKey: 'salary',
      material: Icons.account_balance_rounded,
      cupertino: CupertinoIcons.money_dollar_circle_fill,
    ),
    'Freelance': const _CategorySpec(
      iconKey: 'freelance',
      material: Icons.work_rounded,
      cupertino: CupertinoIcons.briefcase_fill,
    ),
    'Business': const _CategorySpec(
      iconKey: 'business',
      material: Icons.storefront_rounded,
      cupertino: CupertinoIcons.bag_badge_plus,
    ),
    'Investment': const _CategorySpec(
      iconKey: 'investment',
      material: Icons.trending_up_rounded,
      cupertino: CupertinoIcons.chart_bar_alt_fill,
    ),
    'Rental Income': const _CategorySpec(
      iconKey: 'rental-income',
      material: Icons.home_work_rounded,
      cupertino: CupertinoIcons.house_fill,
    ),
    'Bonus': const _CategorySpec(
      iconKey: 'bonus',
      material: Icons.workspace_premium_rounded,
      cupertino: CupertinoIcons.star_fill,
    ),
    'Gift': const _CategorySpec(
      iconKey: 'gift',
      material: Icons.card_giftcard_rounded,
      cupertino: CupertinoIcons.gift_fill,
    ),
    'Pets': const _CategorySpec(
      iconKey: 'pets',
      material: Icons.pets_rounded,
      cupertino: CupertinoIcons.paw_solid,
    ),
    'Home': const _CategorySpec(
      iconKey: 'home',
      material: Icons.home_rounded,
      cupertino: CupertinoIcons.house_fill,
    ),
    'Utilities': const _CategorySpec(
      iconKey: 'utilities',
      material: Icons.bolt_rounded,
      cupertino: CupertinoIcons.bolt_fill,
    ),
    'Phone': const _CategorySpec(
      iconKey: 'phone',
      material: Icons.phone_iphone_rounded,
      cupertino: CupertinoIcons.phone_fill,
    ),
    'Internet': const _CategorySpec(
      iconKey: 'internet',
      material: Icons.wifi_rounded,
      cupertino: CupertinoIcons.wifi,
    ),
    'Insurance': const _CategorySpec(
      iconKey: 'insurance',
      material: Icons.shield_rounded,
      cupertino: CupertinoIcons.shield_fill,
    ),
    'Fuel': const _CategorySpec(
      iconKey: 'fuel',
      material: Icons.local_gas_station_rounded,
      cupertino: CupertinoIcons.flame_fill,
    ),
    'Parking': const _CategorySpec(
      iconKey: 'parking',
      material: Icons.local_parking_rounded,
      cupertino: CupertinoIcons.map_pin,
    ),
    'Repairs': const _CategorySpec(
      iconKey: 'repairs',
      material: Icons.handyman_rounded,
      cupertino: CupertinoIcons.hammer_fill,
    ),
    'Beauty': const _CategorySpec(
      iconKey: 'beauty',
      material: Icons.content_cut_rounded,
      cupertino: CupertinoIcons.scissors,
    ),
    'Fitness': const _CategorySpec(
      iconKey: 'fitness',
      material: Icons.fitness_center_rounded,
      cupertino: CupertinoIcons.sportscourt_fill,
    ),
    'Charity': const _CategorySpec(
      iconKey: 'charity',
      material: Icons.volunteer_activism_rounded,
      cupertino: CupertinoIcons.heart_circle_fill,
    ),
    'Books': const _CategorySpec(
      iconKey: 'books',
      material: Icons.menu_book_rounded,
      cupertino: CupertinoIcons.book_fill,
    ),
    'Clothing': const _CategorySpec(
      iconKey: 'clothing',
      material: Icons.checkroom_rounded,
      cupertino: CupertinoIcons.tag_fill,
    ),
    'Taxes': const _CategorySpec(
      iconKey: 'taxes',
      material: Icons.request_quote_rounded,
      cupertino: CupertinoIcons.doc_text_fill,
    ),
    'Childcare': const _CategorySpec(
      iconKey: 'childcare',
      material: Icons.child_care_rounded,
      cupertino: CupertinoIcons.person_2_fill,
    ),
    'Pharmacy': const _CategorySpec(
      iconKey: 'pharmacy',
      material: Icons.local_pharmacy_rounded,
      cupertino: CupertinoIcons.bandage_fill,
    ),
    'Events': const _CategorySpec(
      iconKey: 'events',
      material: Icons.event_rounded,
      cupertino: CupertinoIcons.calendar,
    ),
    'Savings': const _CategorySpec(
      iconKey: 'savings',
      material: Icons.savings_rounded,
      cupertino: CupertinoIcons.money_dollar_circle_fill,
    ),
    'Bank': const _CategorySpec(
      iconKey: 'bank',
      material: Icons.account_balance_rounded,
      cupertino: CupertinoIcons.building_2_fill,
    ),
    'Other': const _CategorySpec(
      iconKey: 'other',
      material: Icons.more_horiz_rounded,
      cupertino: CupertinoIcons.ellipsis_circle_fill,
    ),
  };

  static final Map<String, _CategorySpec> _specsByIconKey = {
    for (final spec in _specs.values) spec.iconKey: spec,
  };

  static IconData forCategory(String category, {String? iconKey}) =>
      visualFor(category, iconKey: iconKey).icon;

  static Color accentFor(
    String category, {
    String? type,
    String? colorKey,
  }) =>
      visualFor(category, type: type, colorKey: colorKey).accent;

  static Color tintFor(
    String category, {
    String? type,
    String? colorKey,
  }) =>
      visualFor(category, type: type, colorKey: colorKey).tint;

  static Widget rawIcon(
    String category, {
    double size = 16,
    String? type,
    String? iconKey,
    String? colorKey,
  }) {
    final visual = visualFor(
      category,
      type: type,
      iconKey: iconKey,
      colorKey: colorKey,
    );
    return ConsciaGlyph.category(
      visual.iconKey,
      size: size,
      color: visual.accent,
      strokeWidth: size * 0.085,
    );
  }

  static CategoryVisual visualFor(
    String category, {
    String? type,
    String? iconKey,
    String? colorKey,
  }) {
    final fallbackIconKey = defaultIconKeyFor(category);
    final resolvedIconKey =
        _clean(iconKey).isNotEmpty ? _clean(iconKey) : fallbackIconKey;
    final spec = _specsByIconKey[resolvedIconKey] ??
        _specsByIconKey[fallbackIconKey] ??
        _specs['Other']!;
    final resolvedColorKey = _clean(colorKey).isNotEmpty
        ? _clean(colorKey)
        : defaultColorKeyFor(category, type: type);
    final color = colorOptions.firstWhere(
      (option) => option.key == resolvedColorKey,
      orElse: () => colorOptions.firstWhere(
        (option) => option.key == defaultColorKeyFor(category, type: type),
      ),
    );

    return CategoryVisual(
      iconKey: spec.iconKey,
      colorKey: color.key,
      icon: spec.icon(_isIOS),
      accent: color.accent,
      tint: color.tint,
    );
  }

  static String defaultIconKeyFor(String category) {
    final normalized = _normalize(category);
    return _specsByIconKey.containsKey(normalized) ? normalized : 'other';
  }

  static String defaultColorKeyFor(String category, {String? type}) {
    final normalized = _normalize(category);
    final isIncome = type?.toLowerCase() == 'income';
    return switch (normalized) {
      'dining' => 'green',
      'groceries' => 'orange',
      'bills' => 'pink',
      'shopping' => 'blue',
      'transport' => 'cyan',
      'entertainment' => 'violet',
      'education' => 'blue',
      'coffee' => 'orange',
      'gift' => 'pink',
      'travel' => 'cyan',
      'gaming' => 'violet',
      'health' => 'pink',
      'subscriptions' => 'blue',
      'salary' => 'teal',
      'freelance' => 'orange',
      'business' => 'violet',
      'investment' => 'green',
      'rental-income' => 'cyan',
      'bonus' => 'amber',
      'savings' => 'emerald',
      'bank' => 'slate',
      'other' => isIncome ? 'teal' : 'cyan',
      _ => _deterministicColorKey(normalized, isIncome: isIncome),
    };
  }

  static String _deterministicColorKey(
    String normalized, {
    required bool isIncome,
  }) {
    final palette = isIncome
        ? const ['teal', 'green', 'amber', 'cyan', 'violet']
        : const ['green', 'orange', 'pink', 'blue', 'cyan', 'violet'];
    final sum = normalized.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return palette[sum.abs() % palette.length];
  }

  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(_slugPattern, '-').replaceAll(
            RegExp(r'^-+|-+$'),
            '',
          );

  static Widget trialFontPickerIcon(
    String category, {
    required String iconKey,
    required String colorKey,
    required double size,
    Key? key,
  }) {
    final visual = visualFor(
      category,
      iconKey: iconKey,
      colorKey: colorKey,
    );
    return ConsciaGlyph.category(
      visual.iconKey,
      key: key,
      size: size,
      color: visual.accent,
      strokeWidth: size * 0.085,
    );
  }

  static String _clean(String? value) => value?.trim().toLowerCase() ?? '';

  static Widget badge(
    String category, {
    double size = 20,
    double? strokeWidth,
    bool filled = true,
    bool selected = false,
    String? type,
    String? iconKey,
    String? colorKey,
  }) {
    return _CategoryBadge(
      visual: visualFor(
        category,
        type: type,
        iconKey: iconKey,
        colorKey: colorKey,
      ),
      size: size,
      strokeWidth: strokeWidth,
      filled: filled,
      selected: selected,
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.visual,
    required this.size,
    required this.strokeWidth,
    required this.filled,
    required this.selected,
  });

  final CategoryVisual visual;
  final double size;
  final double? strokeWidth;
  final bool filled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bg = filled
        ? visual.tint
        : visual.tint.withValues(alpha: selected ? 0.9 : 0.55);
    final fg = selected ? visual.accent.withValues(alpha: 0.96) : visual.accent;

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
              ? visual.accent.withValues(alpha: 0.18)
              : Colors.transparent,
        ),
      ),
      child: Center(
        child: ConsciaGlyph.category(
          visual.iconKey,
          color: fg,
          size: size,
          strokeWidth: strokeWidth ?? (size * 0.085),
        ),
      ),
    );
  }
}

class _CategorySpec {
  const _CategorySpec({
    required this.iconKey,
    required this.material,
    required this.cupertino,
  });

  final String iconKey;
  final IconData material;
  final IconData cupertino;

  IconData icon(bool isIOS) => isIOS ? cupertino : material;
}

class CategoryVisual {
  const CategoryVisual({
    required this.iconKey,
    required this.colorKey,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final String iconKey;
  final String colorKey;
  final IconData icon;
  final Color accent;
  final Color tint;
}

class CategoryColorOption {
  const CategoryColorOption({
    required this.key,
    required this.label,
    required this.accent,
    required this.tint,
  });

  final String key;
  final String label;
  final Color accent;
  final Color tint;
}

class CategoryIconOption {
  const CategoryIconOption({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;
}
