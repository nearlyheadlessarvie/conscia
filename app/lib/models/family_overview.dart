class FamilyOverview {
  const FamilyOverview({
    required this.familySpaceId,
    required this.budgets,
    required this.recentActivity,
    required this.recurringItems,
  });

  final String familySpaceId;
  final List<FamilyBudgetOverview> budgets;
  final List<FamilyActivity> recentActivity;
  final List<FamilyRecurringOverview> recurringItems;

  factory FamilyOverview.fromJson(Map<String, dynamic> json) {
    return FamilyOverview(
      familySpaceId: json['familySpaceId'] as String,
      budgets: (json['budgets'] as List<dynamic>? ?? [])
          .map((item) => FamilyBudgetOverview.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      recentActivity: (json['recentActivity'] as List<dynamic>? ?? [])
          .map((item) => FamilyActivity.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
      recurringItems: (json['recurringItems'] as List<dynamic>? ?? [])
          .map((item) => FamilyRecurringOverview.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

class FamilyBudgetOverview {
  const FamilyBudgetOverview({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.spentThisMonth,
    required this.usagePercent,
    required this.currencyCode,
  });

  final String id;
  final String category;
  final double monthlyLimit;
  final double spentThisMonth;
  final int usagePercent;
  final String currencyCode;

  factory FamilyBudgetOverview.fromJson(Map<String, dynamic> json) {
    return FamilyBudgetOverview(
      id: json['id'] as String,
      category: json['category'] as String,
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      spentThisMonth: (json['spentThisMonth'] as num).toDouble(),
      usagePercent: json['usagePercent'] as int? ?? 0,
      currencyCode: json['currencyCode'] as String? ?? 'PHP',
    );
  }
}

class FamilyActivity {
  const FamilyActivity({
    required this.id,
    required this.label,
    required this.category,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.date,
  });

  final String id;
  final String label;
  final String category;
  final String type;
  final double amount;
  final String currencyCode;
  final DateTime date;

  factory FamilyActivity.fromJson(Map<String, dynamic> json) {
    return FamilyActivity(
      id: json['id'] as String,
      label: json['label'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'PHP',
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class FamilyRecurringOverview {
  const FamilyRecurringOverview({
    required this.id,
    required this.label,
    required this.category,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.cadence,
    required this.nextRunAt,
  });

  final String id;
  final String label;
  final String category;
  final String type;
  final double amount;
  final String currencyCode;
  final String cadence;
  final DateTime nextRunAt;

  factory FamilyRecurringOverview.fromJson(Map<String, dynamic> json) {
    return FamilyRecurringOverview(
      id: json['id'] as String,
      label: json['label'] as String,
      category: json['category'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'PHP',
      cadence: json['cadence'] as String,
      nextRunAt: DateTime.parse(json['nextRunAt'] as String),
    );
  }
}
