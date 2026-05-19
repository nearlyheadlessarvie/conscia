import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../providers/location_assistance_provider.dart';

class SmartMerchantSuggestionStrip extends StatefulWidget {
  const SmartMerchantSuggestionStrip({
    super.key,
    required this.focusNode,
    required this.suggestions,
    required this.onMerchantSelected,
    required this.child,
    this.enabled = true,
  });

  final FocusNode focusNode;
  final LocationAssistanceSuggestions suggestions;
  final ValueChanged<String> onMerchantSelected;
  final Widget child;
  final bool enabled;

  @override
  State<SmartMerchantSuggestionStrip> createState() =>
      _SmartMerchantSuggestionStripState();
}

class _SmartMerchantSuggestionStripState
    extends State<SmartMerchantSuggestionStrip> {
  bool get _shouldShow =>
      widget.enabled &&
      widget.focusNode.hasFocus &&
      widget.suggestions.nearbyMerchants.isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant SmartMerchantSuggestionStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      widget.focusNode.addListener(_handleFocusChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        widget.child,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _shouldShow
              ? TextFieldTapRegion(
                  child: _MerchantSuggestionRail(
                    key: const ValueKey('smart-merchant-suggestion-strip'),
                    suggestions: widget.suggestions.nearbyMerchants,
                    onSelected: widget.onMerchantSelected,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _MerchantSuggestionRail extends StatelessWidget {
  const _MerchantSuggestionRail({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final merchant = suggestions[index];
            return ActionChip(
              label: Text(
                merchant,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.ink.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
              backgroundColor: colors.surfaceMuted,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onPressed: () => onSelected(merchant),
            );
          },
        ),
      ),
    );
  }
}
