import 'package:dio/dio.dart';

class AdminUserLookup {
  const AdminUserLookup({
    required this.userId,
    required this.email,
    required this.isLifetime,
    required this.source,
    required this.isActive,
  });

  final String userId;
  final String email;
  final bool isLifetime;
  final String source;
  final bool isActive;

  factory AdminUserLookup.fromJson(Map<String, dynamic> json) {
    return AdminUserLookup(
      userId: json['userId'] as String,
      email: json['email'] as String,
      isLifetime: json['isLifetime'] as bool? ?? false,
      source: json['source'] as String? ?? 'none',
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}

class AdminEntitlementService {
  AdminEntitlementService(this._dio);

  final Dio _dio;

  Future<AdminUserLookup> lookupByEmail(String email) async {
    final response = await _dio.get(
      'admin/users/by-email',
      queryParameters: {'email': email},
    );
    return AdminUserLookup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminUserLookup> grantLifetimePremium(
      String userId, String note) async {
    final response = await _dio.put(
      'admin/entitlements/premium-lifetime/$userId',
      data: {
        'grantedBy': 'app-admin-screen',
        'note': note,
      },
    );
    return AdminUserLookup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminUserLookup> revokeLifetimePremium(String userId) async {
    final response = await _dio.delete(
      'admin/entitlements/premium-lifetime/$userId',
    );
    return AdminUserLookup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminUserLookup> provisionReviewer({
    required String email,
    required String temporaryPassword,
    required bool grantLifetimePremium,
    required String note,
  }) async {
    final response = await _dio.post(
      'admin/reviewer-accounts',
      data: {
        'email': email,
        'temporaryPassword': temporaryPassword,
        'grantLifetimePremium': grantLifetimePremium,
        'note': note,
      },
    );
    return AdminUserLookup.fromJson(response.data as Map<String, dynamic>);
  }
}
