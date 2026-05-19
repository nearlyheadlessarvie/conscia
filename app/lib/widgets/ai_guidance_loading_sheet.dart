import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'ai_guidance_chat.dart';
import 'thinking_cloud.dart';

class AiGuidanceLoadingSheet extends StatelessWidget {
  const AiGuidanceLoadingSheet({
    super.key,
    required this.keyPrefix,
    required this.scrollController,
    required this.title,
    required this.message,
    this.detail,
    this.cloudSize = 208,
  });

  final String keyPrefix;
  final ScrollController scrollController;
  final String title;
  final String message;
  final Widget? detail;
  final double cloudSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      key: ValueKey('ai-guidance-loading-sheet-$keyPrefix'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const AiGuidanceSheetHandle(),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 24),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: colors.mutedInk),
        ),
        const SizedBox(height: 10),
        Center(child: ThinkingCloudWidget(size: cloudSize)),
        if (detail != null) ...[
          const SizedBox(height: 14),
          detail!,
        ],
      ],
    );
  }
}
