class FamilyInvite {
  const FamilyInvite({
    required this.id,
    required this.familySpaceId,
    required this.familySpaceName,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String familySpaceId;
  final String familySpaceName;
  final String email;
  final String role;
  final DateTime createdAt;
  final DateTime expiresAt;

  factory FamilyInvite.fromJson(Map<String, dynamic> json) {
    return FamilyInvite(
      id: json['id'] as String,
      familySpaceId: json['familySpaceId'] as String,
      familySpaceName: json['familySpaceName'] as String? ?? 'Family Space',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'Contributor',
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}
