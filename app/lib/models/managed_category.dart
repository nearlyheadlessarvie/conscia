class ManagedCategory {
  const ManagedCategory({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.type,
    required this.scope,
    required this.iconKey,
    required this.colorKey,
    required this.isArchived,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
    this.familySpaceId,
  });

  final String id;
  final String name;
  final String normalizedName;
  final String type;
  final String scope;
  final String? familySpaceId;
  final String? iconKey;
  final String? colorKey;
  final bool isArchived;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isExpense => type.toLowerCase() == 'expense';
  bool get isIncome => type.toLowerCase() == 'income';
  bool get isPersonal => scope.toLowerCase() == 'personal';

  factory ManagedCategory.fromJson(Map<String, dynamic> json) {
    return ManagedCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      normalizedName: json['normalizedName']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Expense',
      scope: json['scope']?.toString() ?? 'Personal',
      familySpaceId: json['familySpaceId']?.toString(),
      iconKey: json['iconKey']?.toString(),
      colorKey: json['colorKey']?.toString(),
      isArchived: json['isArchived'] == true,
      isDefault: json['isDefault'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
