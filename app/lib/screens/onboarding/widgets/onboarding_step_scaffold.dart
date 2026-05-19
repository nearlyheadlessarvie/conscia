import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../widgets/conscia_app_bar.dart';
import '../../../widgets/single_select_list.dart';

class OnboardingStepScaffold extends StatefulWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.appBarTitle,
    required this.stepLabel,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.children,
    this.heroChips = const [],
    this.actions,
    this.bottom,
  });

  final String appBarTitle;
  final String stepLabel;
  final String heroTitle;
  final String heroSubtitle;
  final List<Widget> children;
  final List<Widget> heroChips;
  final List<Widget>? actions;
  final Widget? bottom;

  @override
  State<OnboardingStepScaffold> createState() => _OnboardingStepScaffoldState();
}

class _OnboardingStepScaffoldState extends State<OnboardingStepScaffold> {
  final _appBarScrollProgress = ValueNotifier<double>(0);
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncAppBarProgressFromController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncAppBarProgressFromController();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_syncAppBarProgressFromController);
    _scrollController.dispose();
    _appBarScrollProgress.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      _syncAppBarProgressFromPixels(notification.metrics.pixels);
    }
    return false;
  }

  void _syncAppBarProgressFromController() {
    if (!_scrollController.hasClients) return;
    _syncAppBarProgressFromPixels(_scrollController.offset);
  }

  void _syncAppBarProgressFromPixels(double pixels) {
    final nextProgress = (pixels / 10).clamp(0.0, 1.0);
    if (_appBarScrollProgress.value != nextProgress) {
      _appBarScrollProgress.value = nextProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return ConsciaAppBarScrollScope(
      scrollProgress: _appBarScrollProgress,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: ConsciaAppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.appBarTitle),
          actions: widget.actions,
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.pageTop, colors.pageBottom],
              ),
            ),
            child: CustomScrollView(
              key: PageStorageKey('onboarding-${widget.appBarTitle}'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _OnboardingHero(
                    stepLabel: widget.stepLabel,
                    title: widget.heroTitle,
                    subtitle: widget.heroSubtitle,
                    chips: widget.heroChips,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      28 + (widget.bottom == null ? keyboardInset : 0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.children,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: widget.bottom == null
            ? null
            : AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  20 + keyboardInset + bottomSafeArea,
                ),
                child: widget.bottom!,
              ),
      ),
    );
  }
}

class OnboardingHeroChip extends StatelessWidget {
  const OnboardingHeroChip({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceRaised.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border.withValues(alpha: 0.46)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: colors.deepNavy),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingGroupedOptionList<T> extends StatelessWidget {
  const OnboardingGroupedOptionList({
    super.key,
    required this.options,
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> options;
  final T? value;
  final String Function(T option) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleSelectList<T>(
      options: options,
      value: value,
      titleBuilder: labelBuilder,
      onChanged: onChanged,
    );
  }
}

class OnboardingActionList extends StatelessWidget {
  const OnboardingActionList({
    super.key,
    required this.children,
    this.indent = 56,
  });

  final List<Widget> children;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1)
            Padding(
              padding: EdgeInsets.only(left: indent),
              child: Divider(height: 1, color: colors.border),
            ),
        ],
      ],
    );
  }
}

class OnboardingInlineNote extends StatelessWidget {
  const OnboardingInlineNote({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.expenseSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, size: 15, color: colors.expense),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.expense,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({
    required this.stepLabel,
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  final String stepLabel;
  final String title;
  final String subtitle;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppLayout.screenPadding,
        AppLayout.bleedingHeroTop(context),
        AppLayout.screenPadding,
        AppLayout.heroBottomPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.navySoft.withValues(alpha: 0.72),
            colors.paper,
            colors.amberSoft.withValues(alpha: 0.84),
          ],
          stops: const [0, 0.48, 1],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stepLabel.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              color: colors.deepNavy,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.ink,
              height: 1.35,
            ),
          ),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: chips,
            ),
          ],
        ],
      ),
    );
  }
}
