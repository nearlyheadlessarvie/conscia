import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Light Theme ──────────────────────────────────────────────────────

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF18245C),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE9EDFF),
      onPrimaryContainer: Color(0xFF18245C),
      secondary: Color(0xFFFFB300),
      onSecondary: Color(0xFF18245C),
      secondaryContainer: Color(0xFFFFF2C8),
      onSecondaryContainer: Color(0xFF18245C),
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF171421),
      onSurfaceVariant: Color(0xFF6F687A),
      outline: Color(0xFF9B94A8),
      outlineVariant: Color(0xFFE1E3EF),
      error: Color(0xFFE53935),
      onError: Color(0xFFFFFFFF),
      shadow: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFFFDF8),
      textTheme: _buildTextTheme(Brightness.light),
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          disabledBackgroundColor: colorScheme.outlineVariant,
          textStyle: _buttonTextStyle(Brightness.light),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          textStyle: _buttonTextStyle(Brightness.light),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          textStyle: _buttonTextStyle(Brightness.light),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          foregroundColor: colorScheme.primary,
          textStyle: _buttonTextStyle(Brightness.light),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x14767680),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          14,
          22,
          14,
          8,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFFFFDF8),
        modalBackgroundColor: Color(0xFFFFFDF8),
        surfaceTintColor: Colors.transparent,
        dragHandleColor: Color(0xFFE1E3EF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 84,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFFFFFDF8),
        foregroundColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      extensions: const [AppColors.light],
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF7986CB),
      onPrimary: Color(0xFF1A237E),
      primaryContainer: Color(0xFF283593),
      onPrimaryContainer: Color(0xFFC5CAE9),
      secondary: Color(0xFFFFD54F),
      onSecondary: Color(0xFF1A237E),
      secondaryContainer: Color(0xFF5C4B00),
      onSecondaryContainer: Color(0xFFFFECB3),
      surface: Color(0xFF1E1E2E),
      onSurface: Color(0xFFE6E1E5),
      onSurfaceVariant: Color(0xFFCAC4D0),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      shadow: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      textTheme: _buildTextTheme(Brightness.dark),
      splashFactory: InkSparkle.splashFactory,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          disabledBackgroundColor: colorScheme.outlineVariant,
          textStyle: _buttonTextStyle(Brightness.dark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          textStyle: _buttonTextStyle(Brightness.dark),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          textStyle: _buttonTextStyle(Brightness.dark),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          foregroundColor: colorScheme.primary,
          textStyle: _buttonTextStyle(Brightness.dark),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x1F767680),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          14,
          22,
          14,
          8,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0D1117),
        modalBackgroundColor: Color(0xFF0D1117),
        surfaceTintColor: Colors.transparent,
        dragHandleColor: Color(0xFF334155),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 84,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: const Color(0xFF0D1117),
        foregroundColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
      ),
      extensions: const [AppColors.dark],
    );
  }

  // ── Typography ───────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light
        ? const Color(0xFF171421)
        : const Color(0xFFE6E1E5);

    return TextTheme(
      displayLarge: GoogleFonts.libreBaskerville(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.02,
        color: color,
      ),
      displayMedium: GoogleFonts.libreBaskerville(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.04,
        color: color,
      ),
      displaySmall: GoogleFonts.libreBaskerville(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.06,
        color: color,
      ),
      headlineLarge: GoogleFonts.libreBaskerville(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.08,
        color: color,
      ),
      headlineMedium: GoogleFonts.libreBaskerville(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: color,
      ),
      headlineSmall: GoogleFonts.libreBaskerville(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.12,
        color: color,
      ),
      titleLarge: GoogleFonts.libreBaskerville(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.12,
        color: color,
      ),
      titleMedium: GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0,
        color: color,
      ),
      titleSmall: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
        color: color,
      ),
      bodyLarge: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.38,
        color: color,
      ),
      bodyMedium: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.36,
        color: color,
      ),
      bodySmall: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.34,
        color: color,
      ),
      labelLarge: GoogleFonts.nunitoSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
        color: color,
      ),
      labelMedium: GoogleFonts.nunitoSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: color,
      ),
      labelSmall: GoogleFonts.nunitoSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: color,
      ),
    );
  }

  static TextStyle _buttonTextStyle(Brightness brightness) {
    final color = brightness == Brightness.dark
        ? const Color(0xFFE6E1E5)
        : const Color(0xFF171421);

    return GoogleFonts.nunitoSans(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 0,
      color: color,
    );
  }
}
