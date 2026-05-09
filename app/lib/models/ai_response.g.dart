// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AIResponseImpl _$$AIResponseImplFromJson(Map<String, dynamic> json) =>
    _$AIResponseImpl(
      devilMessage: json['devilMessage'] as String,
      angelMessage: json['angelMessage'] as String,
      neutralMessage: json['neutralMessage'] as String,
      budgetContext: json['budgetContext'] == null
          ? null
          : BudgetContext.fromJson(
              json['budgetContext'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AIResponseImplToJson(_$AIResponseImpl instance) =>
    <String, dynamic>{
      'devilMessage': instance.devilMessage,
      'angelMessage': instance.angelMessage,
      'neutralMessage': instance.neutralMessage,
      'budgetContext': instance.budgetContext,
    };

_$BudgetContextImpl _$$BudgetContextImplFromJson(Map<String, dynamic> json) =>
    _$BudgetContextImpl(
      category: json['category'] as String,
      monthlyLimit: (json['monthlyLimit'] as num).toDouble(),
      currentSpend: (json['currentSpend'] as num).toDouble(),
      percentUsed: (json['percentUsed'] as num).toDouble(),
      currencyCode: json['currencyCode'] as String,
    );

Map<String, dynamic> _$$BudgetContextImplToJson(_$BudgetContextImpl instance) =>
    <String, dynamic>{
      'category': instance.category,
      'monthlyLimit': instance.monthlyLimit,
      'currentSpend': instance.currentSpend,
      'percentUsed': instance.percentUsed,
      'currencyCode': instance.currencyCode,
    };
