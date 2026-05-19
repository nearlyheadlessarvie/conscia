import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/purchase_suggestions_provider.dart';
import '../../../providers/user_provider.dart';

typedef SuggestionCallback = void Function(
    String description, double amount, String category);

class PurchaseSuggestionChips extends ConsumerWidget {
  final SuggestionCallback onSuggestionSelected;

  const PurchaseSuggestionChips({
    super.key,
    required this.onSuggestionSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionsAsync = ref.watch(purchaseSuggestionsProvider);
    final prefs = ref.watch(userPreferencesProvider);

    return suggestionsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your usual',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ...suggestions.map((s) => _SuggestionRow(
                  suggestion: s,
                  locale: prefs.locale,
                  onTap: () =>
                      onSuggestionSelected(s.description, s.amount, s.category),
                )),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final PurchaseSuggestion suggestion;
  final String? locale;
  final VoidCallback onTap;

  const _SuggestionRow({
    required this.suggestion,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(suggestion.description,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              CurrencyFormatter.format(
                suggestion.amount,
                currencyCode: suggestion.currencyCode,
                locale: locale,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            Text(
              suggestion.frequencyLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
