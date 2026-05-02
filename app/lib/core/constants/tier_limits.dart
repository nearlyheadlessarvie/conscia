abstract class TierLimits {
  static const int _unlimited = -1;

  // Free tier
  static const int freeBudgetCategories = 3;
  static const int freeAiAssistsPerMonth = 5;
  static const int freeReflectionsPerMonth = 10;
  static const int freeCurrencies = 1;

  // Premium tier
  static const int premiumBudgetCategories = _unlimited;
  static const int premiumAiAssistsPerMonth = _unlimited;
  static const int premiumReflectionsPerMonth = _unlimited;
  static const int premiumCurrencies = _unlimited;

  static bool isLimitExceeded(int currentCount, int limit) =>
      limit != _unlimited && currentCount >= limit;
}
