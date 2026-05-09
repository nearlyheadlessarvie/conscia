// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BudgetImpl _$$BudgetImplFromJson(Map<String, dynamic> json) => _$BudgetImpl(
      id: json['id'] as String,
      category: json['category'] as String,
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      currentSpend: (json['currentSpend'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
      percentUsed: (json['percentUsed'] as num).toDouble(),
      isOverBudget: json['isOverBudget'] as bool,
    );

Map<String, dynamic> _$$BudgetImplToJson(_$BudgetImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category': instance.category,
      'monthlyLimit': instance.monthlyLimit,
      'currentSpend': instance.currentSpend,
      'currencyCode': instance.currencyCode,
      'percentUsed': instance.percentUsed,
      'isOverBudget': instance.isOverBudget,
    };
