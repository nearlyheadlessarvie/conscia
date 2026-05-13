import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'currency_picker_sheet.dart';

class AmountHeroField extends StatelessWidget {
  const AmountHeroField({
    super.key,
    required this.controller,
    required this.currencyCode,
    required this.isExpense,
    required this.isPremium,
    required this.onChanged,
    required this.onCurrencyChanged,
  });

  final TextEditingController controller;
  final String currencyCode;
  final bool isExpense;
  final bool isPremium;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCurrencyChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final amountColor = isExpense ? colors.expense : colors.income;
    final amountStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w700,
        );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: amountStyle,
      decoration: InputDecoration(
        prefixIconConstraints: const BoxConstraints(),
        prefixIcon: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => CurrencyPickerSheet.show(
            context,
            selectedCode: currencyCode,
            isPremium: isPremium,
            onSelected: onCurrencyChanged,
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(currencyCode, style: amountStyle),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: amountColor.withValues(alpha: 0.65),
                ),
              ],
            ),
          ),
        ),
        hintText: '0',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: amountColor.withValues(alpha: 0.5), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: amountStyle?.copyWith(
          color: amountColor.withValues(alpha: 0.32),
        ),
        filled: true,
        fillColor: colors.surfaceMuted,
      ),
    );
  }
}
