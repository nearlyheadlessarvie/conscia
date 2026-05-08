import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final Widget? inlineAction;

  const AmountInputField({
    super.key,
    required this.controller,
    required this.isExpense,
    required this.currencyCode,
    this.isPremium = false,
    this.onChanged,
    required this.onCurrencyChanged,
    this.inlineAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final prefix = isExpense ? '-' : '+';
    final prefixColor = isExpense
        ? (colors.brightness == Brightness.light
            ? const Color(0xFFD4483B)
            : const Color(0xFFFFB4AB))
        : (colors.brightness == Brightness.light
            ? const Color(0xFF3C9C57)
            : const Color(0xFFA4D8A7));

    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            prefix,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: prefixColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                hintText: '0.00',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.42),
                ),
              ),
            ),
          ),
          if (inlineAction != null) ...[
            const SizedBox(width: 8),
            inlineAction!,
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 10),
          CurrencyBadge(
            currencyCode: currencyCode,
            onTap: () => CurrencyPickerSheet.show(
              context,
              selectedCode: currencyCode,
              isPremium: isPremium,
              onSelected: onCurrencyChanged,
            ),
          ),
        ],
      ),
    );
  }
}
