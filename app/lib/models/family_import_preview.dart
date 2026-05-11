class FamilyImportPreview {
  const FamilyImportPreview({
    required this.familySpaceId,
    required this.warning,
    required this.items,
  });

  final String familySpaceId;
  final String warning;
  final List<FamilyImportItem> items;

  factory FamilyImportPreview.fromJson(Map<String, dynamic> json) {
    return FamilyImportPreview(
      familySpaceId: json['familySpaceId'] as String,
      warning: json['warning'] as String? ??
          'These records will become visible to your Family Space.',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => FamilyImportItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

class FamilyImportItem {
  const FamilyImportItem({
    required this.recordType,
    required this.recordId,
    required this.label,
    required this.category,
    required this.amount,
    required this.currencyCode,
  });

  final String recordType;
  final String recordId;
  final String label;
  final String category;
  final double amount;
  final String currencyCode;

  String get selectionKey => '$recordType:$recordId';

  factory FamilyImportItem.fromJson(Map<String, dynamic> json) {
    return FamilyImportItem(
      recordType: json['recordType'] as String,
      recordId: json['recordId'] as String,
      label: json['label'] as String? ?? 'Shared record',
      category: json['category'] as String? ?? 'Other',
      amount: (json['amount'] as num? ?? 0).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'PHP',
    );
  }
}

class FamilyImportSelection {
  const FamilyImportSelection({
    required this.recordType,
    required this.recordId,
  });

  final String recordType;
  final String recordId;

  Map<String, dynamic> toJson() => {
        'recordType': recordType,
        'recordId': recordId,
      };
}
