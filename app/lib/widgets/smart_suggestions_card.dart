import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../providers/location_assistance_provider.dart';
import 'feed_card.dart';

class SmartSuggestionsCard extends StatelessWidget {
  const SmartSuggestionsCard({
    super.key,
    required this.suggestions,
    required this.onMerchantSelected,
    required this.onCategorySelected,
    required this.categoryAvatarBuilder,
    this.title = 'Smart suggestions nearby',
    this.subtitle,
    this.merchantSectionTitle = 'Nearby merchants',
    this.categorySectionTitle = 'Likely categories',
  });

  final LocationAssistanceSuggestions suggestions;
  final ValueChanged<String> onMerchantSelected;
  final ValueChanged<String> onCategorySelected;
  final Widget Function(String category) categoryAvatarBuilder;
  final String title;
  final String? subtitle;
  final String merchantSectionTitle;
  final String categorySectionTitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).appColors;
    final colorScheme = Theme.of(context).colorScheme;

    return FeedCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          if (suggestions.nearbyMerchants.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              merchantSectionTitle,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.nearbyMerchants
                  .map(
                    (merchant) => ActionChip(
                      label: Text(merchant),
                      backgroundColor: colors.surfaceMuted,
                      onPressed: () => onMerchantSelected(merchant),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (suggestions.likelyCategories.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              categorySectionTitle,
              style: textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.likelyCategories
                  .map(
                    (category) => ActionChip(
                      avatar: categoryAvatarBuilder(category),
                      label: Text(category),
                      backgroundColor: colors.surfaceMuted,
                      onPressed: () => onCategorySelected(category),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
