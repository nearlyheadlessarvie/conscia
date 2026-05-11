class FamilySpace {
  const FamilySpace({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.isReadOnly,
    required this.role,
  });

  final String id;
  final String name;
  final String currencyCode;
  final bool isReadOnly;
  final String role;

  factory FamilySpace.fromJson(Map<String, dynamic> json) {
    return FamilySpace(
      id: json['id'] as String,
      name: json['name'] as String,
      currencyCode: json['currencyCode'] as String? ?? 'PHP',
      isReadOnly: json['isReadOnly'] as bool? ?? false,
      role: json['role'] as String? ?? 'Owner',
    );
  }
}
