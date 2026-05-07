import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required TransactionType type,
    required double amount,
    required String currencyCode,
    required String category,
    @JsonKey(name: 'counterparty', readValue: _readCounterparty)
    String? counterparty,
    required DateTime date,
    @JsonKey(name: 'placeName', readValue: _readPlaceName)
    String? location,
    @Default(0) int regretLevel,
    String? notes,
    required DateTime createdAt,
    double? exchangeRateToBase,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

Object? _readCounterparty(Map json, String _) =>
    json['counterparty'] ?? json['merchant'] ?? json['description'];

Object? _readPlaceName(Map json, String _) =>
    json['placeName'] ?? json['merchantName'] ?? json['location'];
