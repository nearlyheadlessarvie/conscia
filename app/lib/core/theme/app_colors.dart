import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.deepNavy,
    required this.navySoft,
    required this.amber,
    required this.amberSoft,
    required this.paper,
    required this.ink,
    required this.mutedInk,
    required this.softInk,
    required this.border,
    required this.incomeSoft,
    required this.expenseSoft,
    required this.angelSoft,
    required this.devilSoft,
    required this.family,
    required this.familySoft,
    required this.frostedFill,
    required this.income,
    required this.expense,
    required this.pageTop,
    required this.pageBottom,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.sectionBorder,
    required this.heroTint,
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

  final Color deepNavy;
  final Color navySoft;
  final Color amber;
  final Color amberSoft;
  final Color paper;
  final Color ink;
  final Color mutedInk;
  final Color softInk;
  final Color border;
  final Color incomeSoft;
  final Color expenseSoft;
  final Color angelSoft;
  final Color devilSoft;
  final Color family;
  final Color familySoft;
  final Color frostedFill;
  final Color income;
  final Color expense;
  final Color pageTop;
  final Color pageBottom;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color sectionBorder;
  final Color heroTint;
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
    deepNavy: Color(0xFF18245C),
    navySoft: Color(0xFFE9EDFF),
    amber: Color(0xFFFFB300),
    amberSoft: Color(0xFFFFF2C8),
    paper: Color(0xFFFFFDF8),
    ink: Color(0xFF171421),
    mutedInk: Color(0xFF6F687A),
    softInk: Color(0xFF9B94A8),
    border: Color(0xFFE1E3EF),
    incomeSoft: Color(0xFFE5F7EC),
    expenseSoft: Color(0xFFFFE5E2),
    angelSoft: Color(0xFFE0F7FA),
    devilSoft: Color(0xFFFFF3E0),
    family: Color(0xFF35509C),
    familySoft: Color(0xFFE8EDFF),
    frostedFill: Color(0x14767680),
    income: Color(0xFF2E9E55),
    expense: Color(0xFFE53935),
    pageTop: Color(0xFFFFFDF8),
    pageBottom: Color(0xFFFFFDF8),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF7F8FB),
    sectionBorder: Color(0xFFE1E3EF),
    heroTint: Color(0xFFE9EDFF),
    devilBg: Color(0xFFFFF3E0),
    devilAccent: Color(0xFFE65100),
    devilText: Color(0xFF3E2723),
    angelBg: Color(0xFFE0F7FA),
    angelAccent: Color(0xFF00838F),
    angelText: Color(0xFF004D40),
    neutralBg: Color(0xFFF5F5F5),
    neutralAccent: Color(0xFF757575),
    neutralText: Color(0xFF424242),
    budgetHealthy: Color(0xFF2E9E55),
    budgetCaution: Color(0xFFFFC107),
    budgetWarning: Color(0xFFFF9800),
    budgetDanger: Color(0xFFE53935),
  );

  static const dark = AppColors(
    deepNavy: Color(0xFF7986CB),
    navySoft: Color(0xFF2B376F),
    amber: Color(0xFFFFD54F),
    amberSoft: Color(0xFF5A4A16),
    paper: Color(0xFF0D1117),
    ink: Color(0xFFE6E1E5),
    mutedInk: Color(0xFFC0B9CE),
    softInk: Color(0xFF9B94A8),
    border: Color(0xFF334155),
    incomeSoft: Color(0xFF173A24),
    expenseSoft: Color(0xFF492522),
    angelSoft: Color(0xFF0D3B47),
    devilSoft: Color(0xFF4A2C14),
    family: Color(0xFF9AA9E8),
    familySoft: Color(0xFF1D294F),
    frostedFill: Color(0x1F767680),
    income: Color(0xFF81C784),
    expense: Color(0xFFEF9A9A),
    pageTop: Color(0xFF0E1525),
    pageBottom: Color(0xFF0A101C),
    surfaceRaised: Color(0xFF151D2D),
    surfaceMuted: Color(0xFF111827),
    sectionBorder: Color(0xFF22314A),
    heroTint: Color(0xFF18233B),
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
    Color? deepNavy,
    Color? navySoft,
    Color? amber,
    Color? amberSoft,
    Color? paper,
    Color? ink,
    Color? mutedInk,
    Color? softInk,
    Color? border,
    Color? incomeSoft,
    Color? expenseSoft,
    Color? angelSoft,
    Color? devilSoft,
    Color? family,
    Color? familySoft,
    Color? frostedFill,
    Color? income,
    Color? expense,
    Color? pageTop,
    Color? pageBottom,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? sectionBorder,
    Color? heroTint,
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
      deepNavy: deepNavy ?? this.deepNavy,
      navySoft: navySoft ?? this.navySoft,
      amber: amber ?? this.amber,
      amberSoft: amberSoft ?? this.amberSoft,
      paper: paper ?? this.paper,
      ink: ink ?? this.ink,
      mutedInk: mutedInk ?? this.mutedInk,
      softInk: softInk ?? this.softInk,
      border: border ?? this.border,
      incomeSoft: incomeSoft ?? this.incomeSoft,
      expenseSoft: expenseSoft ?? this.expenseSoft,
      angelSoft: angelSoft ?? this.angelSoft,
      devilSoft: devilSoft ?? this.devilSoft,
      family: family ?? this.family,
      familySoft: familySoft ?? this.familySoft,
      frostedFill: frostedFill ?? this.frostedFill,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      pageTop: pageTop ?? this.pageTop,
      pageBottom: pageBottom ?? this.pageBottom,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      sectionBorder: sectionBorder ?? this.sectionBorder,
      heroTint: heroTint ?? this.heroTint,
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
      deepNavy: Color.lerp(deepNavy, other.deepNavy, t)!,
      navySoft: Color.lerp(navySoft, other.navySoft, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberSoft: Color.lerp(amberSoft, other.amberSoft, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      softInk: Color.lerp(softInk, other.softInk, t)!,
      border: Color.lerp(border, other.border, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      angelSoft: Color.lerp(angelSoft, other.angelSoft, t)!,
      devilSoft: Color.lerp(devilSoft, other.devilSoft, t)!,
      family: Color.lerp(family, other.family, t)!,
      familySoft: Color.lerp(familySoft, other.familySoft, t)!,
      frostedFill: Color.lerp(frostedFill, other.frostedFill, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      pageTop: Color.lerp(pageTop, other.pageTop, t)!,
      pageBottom: Color.lerp(pageBottom, other.pageBottom, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      sectionBorder: Color.lerp(sectionBorder, other.sectionBorder, t)!,
      heroTint: Color.lerp(heroTint, other.heroTint, t)!,
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
