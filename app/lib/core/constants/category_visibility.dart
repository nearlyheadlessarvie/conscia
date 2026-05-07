import 'generated/app_constants.g.dart';

List<String> visibleBudgetCategories({
  required bool isPremium,
  required List<String> categories,
}) {
  if (isPremium) {
    return List<String>.unmodifiable(categories);
  }

  final freeCategories =
      expenseCategories.take(FreemiumLimits.freeBudgetCategories).toSet();

  return categories.where(freeCategories.contains).toList(growable: false);
}
