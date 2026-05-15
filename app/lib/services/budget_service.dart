import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class Budget {
  final String id;
  final String category;
  final double monthlyLimit;
  final double spent;
  final String currencyCode;
  final double percentage;
  final bool isOverBudget;
  final String scope;
  final String? familySpaceId;

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.spent,
    required this.currencyCode,
    required this.percentage,
    required this.isOverBudget,
    this.scope = 'personal',
    this.familySpaceId,
  });

  bool get isFamily => scope == 'family';

  factory Budget.fromJson(Map<String, dynamic> json) {
    final limit = (json['monthlyLimit'] as num).toDouble();
    final spend = (json['currentSpend'] as num?)?.toDouble() ?? 0;
    final percentUsed = (json['percentUsed'] as num?)?.toDouble();
    final double normalizedPercentage = percentUsed == null
        ? (limit > 0 ? spend / limit : 0)
        : percentUsed > 1
            ? percentUsed / 100
            : percentUsed;
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      monthlyLimit: limit,
      spent: spend,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      percentage: normalizedPercentage,
      isOverBudget: json['isOverBudget'] as bool? ?? spend > limit,
      scope: _parseScope(json['scope']),
      familySpaceId: json['familySpaceId'] as String?,
    );
  }

  static String _parseScope(Object? value) =>
      value?.toString().toLowerCase() == 'family' ? 'family' : 'personal';

  Budget copyWith({
    String? id,
    String? category,
    double? monthlyLimit,
    double? spent,
    String? currencyCode,
    double? percentage,
    bool? isOverBudget,
    String? scope,
    String? familySpaceId,
  }) {
    final nextLimit = monthlyLimit ?? this.monthlyLimit;
    final nextSpent = spent ?? this.spent;
    return Budget(
      id: id ?? this.id,
      category: category ?? this.category,
      monthlyLimit: nextLimit,
      spent: nextSpent,
      currencyCode: currencyCode ?? this.currencyCode,
      percentage: percentage ?? (nextLimit > 0 ? nextSpent / nextLimit : 0),
      isOverBudget: isOverBudget ?? nextSpent > nextLimit,
      scope: scope ?? this.scope,
      familySpaceId: familySpaceId ?? this.familySpaceId,
    );
  }
}

class CreateBudgetDto {
  final String category;
  final double monthlyLimit;
  final String currencyCode;
  final String scope;
  final String? familySpaceId;

  const CreateBudgetDto({
    required this.category,
    required this.monthlyLimit,
    required this.currencyCode,
    this.scope = 'personal',
    this.familySpaceId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'category': category,
      'monthlyLimit': monthlyLimit,
      'currencyCode': currencyCode,
      'scope': scope.toLowerCase() == 'family' ? 'Family' : 'Personal',
    };
    if (familySpaceId != null) {
      json['familySpaceId'] = familySpaceId;
    }
    return json;
  }
}

class BudgetService {
  final Dio _dio;

  BudgetService(this._dio);

  Future<List<Budget>> list() async {
    try {
      final response = await _dio.get(ApiConstants.budgets);
      final data = response.data as List;
      return data
          .map((e) => Budget.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<Budget> create(CreateBudgetDto dto) async {
    try {
      final response = await _dio.post(
        ApiConstants.budgets,
        data: dto.toJson(),
      );
      return Budget.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<Budget> update(String id, CreateBudgetDto dto) async {
    try {
      final response = await _dio.put(
        ApiConstants.budget(id),
        data: dto.toJson(),
      );
      return Budget.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiConstants.budget(id));
    } on DioException {
      rethrow;
    }
  }
}
