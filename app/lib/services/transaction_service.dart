import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';

class Transaction {
  final String id;
  final double amount;
  final String currencyCode;
  final String category;
  final String description;
  final String type;
  final DateTime date;
  final int? regretLevel;

  const Transaction({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.category,
    required this.description,
    required this.type,
    required this.date,
    this.regretLevel,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      regretLevel: json['regretLevel'] as int?,
    );
  }
}

class PaginatedTransactions {
  final List<Transaction> items;
  final int total;
  final int page;
  final int pageSize;

  const PaginatedTransactions({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  bool get hasMore => page * pageSize < total;
}

class CreateTransactionDto {
  final double amount;
  final String currencyCode;
  final String category;
  final String description;
  final String type;
  final DateTime date;

  const CreateTransactionDto({
    required this.amount,
    required this.currencyCode,
    required this.category,
    required this.description,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'currencyCode': currencyCode,
        'category': category,
        'description': description,
        'type': type,
        'date': date.toIso8601String(),
      };
}

class TransactionService {
  final Dio _dio;

  TransactionService(this._dio);

  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.transactions,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (category != null) 'category': category,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedTransactions(
        items: items,
        total: data['total'] as int? ?? items.length,
        page: page,
        pageSize: pageSize,
      );
    } on DioException {
      rethrow;
    }
  }

  Future<Transaction> getById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.transaction(id));
      return Transaction.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<Transaction> create(CreateTransactionDto dto) async {
    try {
      final response = await _dio.post(
        ApiConstants.transactions,
        data: dto.toJson(),
      );
      return Transaction.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<Transaction> update(String id, CreateTransactionDto dto) async {
    try {
      final response = await _dio.put(
        ApiConstants.transaction(id),
        data: dto.toJson(),
      );
      return Transaction.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiConstants.transaction(id));
    } on DioException {
      rethrow;
    }
  }

  Future<Transaction> updateRegret(String id, int level) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.transaction(id)}/regret',
        data: {'level': level},
      );
      return Transaction.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }
}
