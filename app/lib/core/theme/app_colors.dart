import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.income,
    required this.expense,
    required this.devilBg,
    required this.devilAccent,
    required this.devilText,
    required this.angelBg,
    required this.angelAccent,
    required this.angelText,
    required this.neutralBg,
    required this.neutralAccent,
    required this.neutralText,
    required this.budgetHealthy,
    required this.budgetCaution,
    required this.budgetWarning,
    required this.budgetDanger,
  });

  final Color income;
  final Color expense;
  final Color devilBg;
  final Color devilAccent;
  final Color devilText;
  final Color angelBg;
  final Color angelAccent;
  final Color angelText;
  final Color neutralBg;
  final Color neutralAccent;
  final Color neutralText;
  final Color budgetHealthy;
  final Color budgetCaution;
  final Color budgetWarning;
  final Color budgetDanger;

  static const light = AppColors(
    income: Color(0xFF4CAF50),
    expense: Color(0xFFE53935),
    devilBg: Color(0xFFFFF8E1),
    devilAccent: Color(0xFFE65100),
    devilText: Color(0xFF3E2723),
    angelBg: Color(0xFFE0F7FA),
    angelAccent: Color(0xFF00838F),
    angelText: Color(0xFF004D40),
    neutralBg: Color(0xFFF5F5F5),
    neutralAccent: Color(0xFF757575),
    neutralText: Color(0xFF424242),
    budgetHealthy: Color(0xFF4CAF50),
    budgetCaution: Color(0xFFFFC107),
    budgetWarning: Color(0xFFFF9800),
    budgetDanger: Color(0xFFE53935),
  );

  static const dark = AppColors(
    income: Color(0xFF81C784),
    expense: Color(0xFFEF9A9A),
    devilBg: Color(0xFF3E2723),
    devilAccent: Color(0xFFE65100),
    devilText: Color(0xFFFFE0B2),
    angelBg: Color(0xFF0D3B47),
    angelAccent: Color(0xFF00838F),
    angelText: Color(0xFFB2EBF2),
    neutralBg: Color(0xFF2C2C3A),
    neutralAccent: Color(0xFF757575),
    neutralText: Color(0xFFBDBDBD),
    budgetHealthy: Color(0xFF81C784),
    budgetCaution: Color(0xFFFFD54F),
    budgetWarning: Color(0xFFFFB74D),
    budgetDanger: Color(0xFFEF9A9A),
  );

  @override
  AppColors copyWith({
    Color? income,
    Color? expense,
    Color? devilBg,
    Color? devilAccent,
    Color? devilText,
    Color? angelBg,
    Color? angelAccent,
    Color? angelText,
    Color? neutralBg,
    Color? neutralAccent,
    Color? neutralText,
    Color? budgetHealthy,
    Color? budgetCaution,
    Color? budgetWarning,
    Color? budgetDanger,
  }) {
    return AppColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      devilBg: devilBg ?? this.devilBg,
      devilAccent: devilAccent ?? this.devilAccent,
      devilText: devilText ?? this.devilText,
      angelBg: angelBg ?? this.angelBg,
      angelAccent: angelAccent ?? this.angelAccent,
      angelText: angelText ?? this.angelText,
      neutralBg: neutralBg ?? this.neutralBg,
      neutralAccent: neutralAccent ?? this.neutralAccent,
      neutralText: neutralText ?? this.neutralText,
      budgetHealthy: budgetHealthy ?? this.budgetHealthy,
      budgetCaution: budgetCaution ?? this.budgetCaution,
      budgetWarning: budgetWarning ?? this.budgetWarning,
      budgetDanger: budgetDanger ?? this.budgetDanger,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      devilBg: Color.lerp(devilBg, other.devilBg, t)!,
      devilAccent: Color.lerp(devilAccent, other.devilAccent, t)!,
      devilText: Color.lerp(devilText, other.devilText, t)!,
      angelBg: Color.lerp(angelBg, other.angelBg, t)!,
      angelAccent: Color.lerp(angelAccent, other.angelAccent, t)!,
      angelText: Color.lerp(angelText, other.angelText, t)!,
      neutralBg: Color.lerp(neutralBg, other.neutralBg, t)!,
      neutralAccent: Color.lerp(neutralAccent, other.neutralAccent, t)!,
      neutralText: Color.lerp(neutralText, other.neutralText, t)!,
      budgetHealthy: Color.lerp(budgetHealthy, other.budgetHealthy, t)!,
      budgetCaution: Color.lerp(budgetCaution, other.budgetCaution, t)!,
      budgetWarning: Color.lerp(budgetWarning, other.budgetWarning, t)!,
      budgetDanger: Color.lerp(budgetDanger, other.budgetDanger, t)!,
    );
  }
}

extension AppColorsExtension on ThemeData {
  AppColors get appColors =>
      extension<AppColors>() ??
      (brightness == Brightness.light ? AppColors.light : AppColors.dark);
}
