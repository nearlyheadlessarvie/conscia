import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/category_icons.dart';

class CategoryIconFontPreviewScreen extends StatelessWidget {
  const CategoryIconFontPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Icon Font Trial'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SVG source preview',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These are the first source SVGs for the category icon font trial. Review the shapes here before exporting them through FlutterIcon.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  key: const ValueKey('category-icon-font-preview-grid'),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: CategoryIcons.trialFontIconOptions.length,
                  itemBuilder: (context, index) {
                    final option = CategoryIcons.trialFontIconOptions[index];
                    return _PreviewTile(option: option);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.option});

  final CategoryIconOption option;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final visual = CategoryIcons.visualFor(
      option.label,
      iconKey: option.key,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: visual.tint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Center(
                child: SvgPicture.asset(
                  CategoryIcons.trialFontAssetPath(option.key),
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    visual.accent,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              option.label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${option.key}.svg',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                SvgPicture.asset(
                  CategoryIcons.trialFontAssetPath(option.key),
                  width: 16,
                  height: 16,
                  colorFilter: ColorFilter.mode(
                    colors.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '16px preview',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
