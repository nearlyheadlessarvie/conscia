class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.userId,
    required this.email,
    required this.role,
    required this.joinedAt,
    required this.isCurrentUser,
  });

  final String id;
  final String userId;
  final String email;
  final String role;
  final DateTime joinedAt;
  final bool isCurrentUser;

  bool get isOwner => role.toLowerCase() == 'owner';

  String get displayName {
    final localPart = email.split('@').first.trim();
    return localPart.isEmpty ? email : localPart;
  }

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) return '?';
    final parts = source
        .split(RegExp(r'[\s._-]+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      userId: json['userId'] as String,
      email: json['email'] as String? ?? 'member',
      role: json['role'] as String? ?? 'Viewer',
      joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}
