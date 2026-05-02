import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'currency_badge.dart';
import 'currency_picker_sheet.dart';

class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isExpense;
  final String currencyCode;
  final bool isPremium;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String> onCurrencyChanged;

  const AmountInputField({
    super.key,
    required this.controller,
    required this.isExpense,
    required this.currencyCode,
    this.isPremium = false,
    this.onChanged,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final prefix = isExpense ? '-' : '+';
    final prefixColor = isExpense
        ? (colors.brightness == Brightness.light
            ? const Color(0xFFE53935)
            : const Color(0xFFEF9A9A))
        : (colors.brightness == Brightness.light
            ? const Color(0xFF4CAF50)
            : const Color(0xFF81C784));

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: '0.00',
        hintStyle: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: colors.onSurfaceVariant.withOpacity(0.4),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            prefix,
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: prefixColor,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: CurrencyBadge(
            currencyCode: currencyCode,
            onTap: () => CurrencyPickerSheet.show(
              context,
              selectedCode: currencyCode,
              isPremium: isPremium,
              onSelected: onCurrencyChanged,
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
      ),
    );
  }
}
