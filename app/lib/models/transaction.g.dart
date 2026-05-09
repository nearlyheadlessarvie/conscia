// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TransactionImpl _$$TransactionImplFromJson(Map<String, dynamic> json) =>
    _$TransactionImpl(
      id: json['id'] as String,
      type: $enumDecode(_$TransactionTypeEnumMap, json['type']),
      amount: (json['amount'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      category: json['category'] as String,
      counterparty: _readCounterparty(json, 'counterparty') as String?,
      date: DateTime.parse(json['date'] as String),
      location: _readPlaceName(json, 'placeName') as String?,
      regretLevel: (json['regretLevel'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      exchangeRateToBase: (json['exchangeRateToBase'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$TransactionImplToJson(_$TransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$TransactionTypeEnumMap[instance.type]!,
      'amount': instance.amount,
      'currencyCode': instance.currencyCode,
      'category': instance.category,
      'counterparty': instance.counterparty,
      'date': instance.date.toIso8601String(),
      'placeName': instance.location,
      'regretLevel': instance.regretLevel,
      'notes': instance.notes,
      'createdAt': instance.createdAt.toIso8601String(),
      'exchangeRateToBase': instance.exchangeRateToBase,
    };

const _$TransactionTypeEnumMap = {
  TransactionType.expense: 'expense',
  TransactionType.income: 'income',
};
