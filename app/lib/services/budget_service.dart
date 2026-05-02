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

  const Budget({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.spent,
    required this.currencyCode,
    required this.percentage,
    required this.isOverBudget,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    final limit = (json['monthlyLimit'] as num).toDouble();
    final spend = (json['currentSpend'] as num?)?.toDouble() ?? 0;
    return Budget(
      id: json['id'] as String,
      category: json['category'] as String,
      monthlyLimit: limit,
      spent: spend,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      percentage: (json['percentUsed'] as num?)?.toDouble() ?? (limit > 0 ? spend / limit : 0),
      isOverBudget: json['isOverBudget'] as bool? ?? spend > limit,
    );
  }
}

class CreateBudgetDto {
  final String category;
  final double monthlyLimit;
  final String currencyCode;

  const CreateBudgetDto({
    required this.category,
    required this.monthlyLimit,
    required this.currencyCode,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'monthlyLimit': monthlyLimit,
        'currencyCode': currencyCode,
      };
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
