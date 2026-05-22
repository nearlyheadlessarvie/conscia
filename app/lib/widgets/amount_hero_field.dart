import 'package:flutter/material.dart';
import '../core/constants/app_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/localized_number_input.dart';
import 'currency_picker_sheet.dart';

class AmountHeroField extends StatefulWidget {
  const AmountHeroField({
    super.key,
    required this.controller,
    this.focusNode,
    required this.currencyCode,
    this.locale,
    required this.isExpense,
    required this.isPremium,
    required this.onChanged,
    required this.onCurrencyChanged,
    this.textAlign = TextAlign.end,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String currencyCode;
  final String? locale;
  final bool isExpense;
  final bool isPremium;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCurrencyChanged;
  final TextAlign textAlign;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<AmountHeroField> createState() => _AmountHeroFieldState();
}

class _AmountHeroFieldState extends State<AmountHeroField> {
  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChanged);
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(covariant AmountHeroField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleFocusChanged);
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      _ownsFocusNode = widget.focusNode == null;
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChanged);
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTextChanged);
      widget.controller.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    widget.controller.removeListener(_handleTextChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final amountColor = widget.isExpense ? colors.expense : colors.income;
    final amountStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: amountColor,
          fontWeight: FontWeight.w700,
          height: 1,
        );
    final hintText = LocalizedNumberInput.formatForInput(
      0,
      locale: widget.locale,
    );
    return SizedBox(
      height: 65,
      child: AnimatedContainer(
        key: const ValueKey('amount-hero-field-container'),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _focusNode.hasFocus
                ? amountColor.withValues(alpha: 0.5)
                : colors.border,
            width: _focusNode.hasFocus ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(left: 80, right: 16),
                child: Center(
                  child: SizedBox(
                    key: const ValueKey('amount-editable-line'),
                    height: 34,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (widget.controller.text.isEmpty)
                          IgnorePointer(
                            child: Align(
                              alignment: _alignmentFor(widget.textAlign),
                              child: Text(
                                hintText,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: amountStyle?.copyWith(
                                  color: amountColor.withValues(alpha: 0.32),
                                ),
                              ),
                            ),
                          ),
                        EditableText(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          autofocus: widget.autofocus,
                          textInputAction: widget.textInputAction,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            LocalizedNumberInput.formatter(widget.locale)
                          ],
                          maxLines: 1,
                          textAlign: widget.textAlign,
                          style: amountStyle!,
                          cursorColor: amountColor,
                          backgroundCursorColor: colors.softInk,
                          selectionColor: amountColor.withValues(alpha: 0.18),
                          enableInteractiveSelection: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => CurrencyPickerSheet.show(
                  context,
                  selectedCode: widget.currencyCode,
                  isPremium: widget.isPremium,
                  onSelected: widget.onCurrencyChanged,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.currencyCode,
                        key: const ValueKey('amount-currency-label'),
                        style: amountStyle,
                      ),
                      const SizedBox(width: 2),
                      AppIcons.icon(
                        AppIconKey.arrowDown,
                        color: amountColor.withValues(alpha: 0.65),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Alignment _alignmentFor(TextAlign textAlign) {
    return switch (textAlign) {
      TextAlign.left || TextAlign.start => Alignment.centerLeft,
      TextAlign.center => Alignment.center,
      _ => Alignment.centerRight,
    };
  }
}
