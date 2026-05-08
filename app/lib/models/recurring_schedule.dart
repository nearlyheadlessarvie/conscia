class RecurringDraft {
  final bool enabled;
  final String cadence;
  final DateTime? endDate;

  const RecurringDraft({
    required this.enabled,
    required this.cadence,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'cadence': cadence};
    if (endDate != null) {
      json['endDate'] = endDate!.toIso8601String();
    }
    return json;
  }
}

class RecurringSchedule {
  final String id;
  final String type;
  final double amount;
  final String currencyCode;
  final String category;
  final String? counterparty;
  final String cadence;
  final DateTime startDate;
  final DateTime nextRunAt;
  final DateTime? endDate;
  final bool isActive;

  const RecurringSchedule({
    required this.id,
    required this.type,
    required this.amount,
    required this.currencyCode,
    required this.category,
    this.counterparty,
    required this.cadence,
    required this.startDate,
    required this.nextRunAt,
    this.endDate,
    required this.isActive,
  });

  factory RecurringSchedule.fromJson(Map<String, dynamic> json) {
    return RecurringSchedule(
      id: json['id'] as String,
      type: (json['type'] as String).toLowerCase(),
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      category: json['category'] as String,
      counterparty: json['counterparty'] as String?,
      cadence: json['cadence'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      nextRunAt: DateTime.parse(json['nextRunAt'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
