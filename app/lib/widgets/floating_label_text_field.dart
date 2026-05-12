import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class FloatingLabelTextField extends StatefulWidget {
  const FloatingLabelTextField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.obscureText = false,
    this.errorText,
    this.enabled = true,
    this.trailing,
    this.maxLines = 1,
    this.minLines,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final String? errorText;
  final bool enabled;
  final Widget? trailing;
  final int maxLines;
  final int? minLines;
  final Iterable<String>? autofillHints;

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
            left: 14,
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
              14,
              _isRaised ? 22 : 22,
              widget.trailing == null ? 14 : 48,
              8,
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onChanged: widget.onChanged,
              obscureText: widget.obscureText,
              enabled: widget.enabled,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              autofillHints: widget.autofillHints,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.ink,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
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
