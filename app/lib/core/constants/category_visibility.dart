const Set<String> freeTransactionCategories = {
  'Dining',
  'Groceries',
  'Salary',
};

bool isFreeTransactionCategory(String category) {
  return freeTransactionCategories.contains(category);
}

List<String> visibleTransactionCategories({
  required bool isPremium,
  required bool isExpense,
  required List<String> categories,
}) {
  if (isPremium) {
    return List<String>.unmodifiable(categories);
  }

  return categories
      .where(
        (category) => isExpense
            ? category != 'Salary' && isFreeTransactionCategory(category)
            : category == 'Salary',
      )
      .toList(growable: false);
}

List<String> visibleBudgetCategories({
  required bool isPremium,
  required List<String> categories,
}) {
  return List<String>.unmodifiable(categories);
}
