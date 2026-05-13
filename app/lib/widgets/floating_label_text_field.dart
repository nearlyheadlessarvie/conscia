import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

class FloatingLabelTextField extends StatefulWidget {
  const FloatingLabelTextField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.prefix,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.obscureText = false,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.trailing,
    this.maxLines = 1,
    this.minLines,
    this.autofillHints,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.maxLength,
    this.counterText,
    this.enableSuggestions = true,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final Widget? prefix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool obscureText;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final Widget? trailing;
  final int maxLines;
  final int? minLines;
  final Iterable<String>? autofillHints;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final String? counterText;
  final bool enableSuggestions;
  final bool autocorrect;

  @override
  State<FloatingLabelTextField> createState() => _FloatingLabelTextFieldState();
}

class _FloatingLabelTextFieldState extends State<FloatingLabelTextField> {
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;

  bool get _isRaised =>
      _focusNode.hasFocus || widget.controller.text.isNotEmpty;
  bool get _hasError => (widget.errorText?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleStateChanged);
    widget.controller.addListener(_handleStateChanged);
  }

  @override
  void didUpdateWidget(covariant FloatingLabelTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleStateChanged);
      widget.controller.addListener(_handleStateChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_handleStateChanged);
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleStateChanged);
    widget.controller.removeListener(_handleStateChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;
    final leadingInset = widget.prefix == null ? 14.0 : 48.0;
    final isFocused = _focusNode.hasFocus;
    final backgroundColor = _hasError
        ? theme.colorScheme.surface
        : isFocused
            ? theme.colorScheme.surface
            : colors.frostedFill;
    final borderColor = _hasError
        ? colors.expense
        : isFocused
            ? colors.deepNavy
            : colors.border;
    final labelColor = _hasError
        ? colors.expense
        : isFocused
            ? colors.deepNavy
            : _isRaised
                ? colors.mutedInk
                : colors.softInk;

    final field = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: isFocused || _hasError ? 2 : 1.5,
        ),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            left: leadingInset,
            top: _isRaised ? 8 : 15,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              style: (_isRaised
                          ? theme.textTheme.labelSmall
                          : theme.textTheme.bodyMedium)
                      ?.copyWith(
                    fontWeight: _isRaised ? FontWeight.w600 : FontWeight.w400,
                    color: labelColor,
                  ) ??
                  TextStyle(
                    fontSize: _isRaised ? 11 : 14,
                    fontWeight: _isRaised ? FontWeight.w600 : FontWeight.w400,
                    color: labelColor,
                  ),
              child: Text(widget.label),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              leadingInset,
              22,
              widget.trailing == null ? 14 : 48,
              8,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              autofillHints: widget.autofillHints,
              textAlign: widget.textAlign,
              inputFormatters: widget.inputFormatters,
              maxLength: widget.maxLength,
              enableSuggestions: widget.enableSuggestions,
              autocorrect: widget.autocorrect,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                counterText: widget.counterText,
              ),
            ),
          ),
          if (widget.prefix != null)
            Positioned(
              left: 14,
              top: 0,
              bottom: 0,
              child: Center(child: widget.prefix!),
            ),
          if (widget.trailing != null)
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(child: widget.trailing!),
            ),
        ],
      ),
    );

    if (!_hasError) {
      return field;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        field,
        const SizedBox(height: 6),
        Text(
          '⚠ ${widget.errorText!}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.expense,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
