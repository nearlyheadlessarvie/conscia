import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/editorial_sticky_header.dart';

class InsightDrilldownScaffold extends StatefulWidget {
  const InsightDrilldownScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  State<InsightDrilldownScaffold> createState() =>
      _InsightDrilldownScaffoldState();
}

class _InsightDrilldownScaffoldState extends State<InsightDrilldownScaffold> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  bool _scrollSyncScheduled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncScrollOffset);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_syncScrollOffset)
      ..dispose();
    super.dispose();
  }

  void _syncScrollOffset() {
    final nextOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    if ((nextOffset - _scrollOffset).abs() < 1) return;
    setState(() => _scrollOffset = nextOffset);
  }

  void _scheduleScrollSync() {
    if (_scrollSyncScheduled) return;
    _scrollSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollSyncScheduled = false;
      if (!mounted) return;
      _syncScrollOffset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final stickyProgress = ((_scrollOffset - 5) / 10).clamp(0.0, 1.0);

    _scheduleScrollSync();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.pageTop, colors.pageBottom],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 28),
              child: widget.child,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: EditorialStickyHeader(
                title: widget.title,
                progress: stickyProgress,
                topPadding: MediaQuery.paddingOf(context).top,
                alwaysShowBack: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
