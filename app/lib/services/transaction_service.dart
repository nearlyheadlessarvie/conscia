import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../models/recurring_schedule.dart';

class Transaction {
  final String id;
  final double amount;
  final String currencyCode;
  final String category;
  final String description;
  final String type;
  final DateTime date;
  final int? regretLevel;
  final String? recurringScheduleId;
  final DateTime? recurringOccurrenceDate;
  final String scope;
  final String? familySpaceId;
  final String? sharedByUserId;
  final String? sharedByInitials;
  final String? sharedByDisplayName;
  final double? exchangeRateToBase;

  const Transaction({
    required this.id,
    required this.amount,
    required this.currencyCode,
    required this.category,
    required this.description,
    required this.type,
    required this.date,
    this.regretLevel,
    this.recurringScheduleId,
    this.recurringOccurrenceDate,
    this.scope = 'personal',
    this.familySpaceId,
    this.sharedByUserId,
    this.sharedByInitials,
    this.sharedByDisplayName,
    this.exchangeRateToBase,
  });

  bool get isRecurring => recurringScheduleId != null;
  bool get isFamily => scope == 'family';

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      category: json['category'] as String,
      description: json['counterparty'] as String? ??
          json['merchant'] as String? ??
          json['description'] as String? ??
          '',
      type: (json['type'] as String).toLowerCase(),
      date: DateTime.parse(json['date'] as String),
      regretLevel: _parseRegretLevel(json['regretLevel']),
      recurringScheduleId: json['recurringScheduleId'] as String?,
      recurringOccurrenceDate: json['recurringOccurrenceDate'] != null
          ? DateTime.parse(json['recurringOccurrenceDate'] as String)
          : null,
      scope: _parseScope(json['scope']),
      familySpaceId: json['familySpaceId'] as String?,
      sharedByUserId: json['sharedByUserId'] as String?,
      sharedByInitials: json['sharedByInitials'] as String?,
      sharedByDisplayName: json['sharedByDisplayName'] as String?,
      exchangeRateToBase: (json['exchangeRateToBase'] as num?)?.toDouble(),
    );
  }

  static int? _parseRegretLevel(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    const map = {'WorthIt': 0, 'NotSure': 1, 'Regret': 2};
    return map[value as String];
  }

  static String _parseScope(dynamic value) {
    if (value is! String) return 'personal';
    return value.toLowerCase() == 'family' ? 'family' : 'personal';
  }
}

class PaginatedTransactions {
  final List<Transaction> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedTransactions({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });
}

class TransactionDateFilter {
  final String kind;
  final DateTime? from;
  final DateTime? to;

  const TransactionDateFilter({
    required this.kind,
    this.from,
    this.to,
  });
}

class CreateTransactionDto {
  final double amount;
  final String currencyCode;
  final String category;
  final String counterparty;
  final String type;
  final DateTime date;
  final String? baseCurrencyCode;
  final double? exchangeRateOverride;
  final RecurringDraft? recurring;
  final String scope;
  final String? familySpaceId;

  const CreateTransactionDto({
    required this.amount,
    required this.currencyCode,
    required this.category,
    required this.counterparty,
    required this.type,
    required this.date,
    this.baseCurrencyCode,
    this.exchangeRateOverride,
    this.recurring,
    this.scope = 'personal',
    this.familySpaceId,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'amount': amount,
      'currencyCode': currencyCode,
      'category': category,
      'counterparty': counterparty,
      'type': _capitalizeType(type),
      'date': date.toIso8601String(),
      'scope': _scopeForApi(scope),
    };
    if (familySpaceId != null) {
      json['familySpaceId'] = familySpaceId;
    }
    if (baseCurrencyCode != null) {
      json['baseCurrencyCode'] = baseCurrencyCode;
    }
    if (exchangeRateOverride != null) {
      json['exchangeRateOverride'] = exchangeRateOverride;
    }
    if (recurring != null && recurring!.enabled) {
      json['recurring'] = recurring!.toJson();
    }
    return json;
  }

  static String _capitalizeType(String t) =>
      t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';

  static String _scopeForApi(String value) =>
      value.toLowerCase() == 'family' ? 'Family' : 'Personal';
}

class TransactionService {
  final Dio _dio;

  TransactionService(this._dio);

  Future<PaginatedTransactions> list({
    int page = 1,
    int pageSize = 20,
    String? category,
    String? scope,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.transactions,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (category != null) 'category': category,
          if (scope != null) 'scope': scope,
          if (from != null && to != null) 'from': from.toIso8601String(),
          if (from != null && to != null) 'to': to.toIso8601String(),
        },
      );
      final data = response.data as Map<String, dynamic>;
      final items = (data['items'] as List)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList();
      return PaginatedTransactions(
        items: items,
        totalCount: data['totalCount'] as int? ?? items.length,
        page: page,
        pageSize: pageSize,
        hasMore: data['hasMore'] as bool? ?? false,
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

  Future<void> updateRegret(String id, int level) async {
    try {
      await _dio.post(
        '${ApiConstants.transaction(id)}/regret',
        data: {'level': level},
      );
    } on DioException {
      rethrow;
    }
  }
}
