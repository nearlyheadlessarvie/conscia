// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'behavioral_insights.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CategoryTrendImpl _$$CategoryTrendImplFromJson(Map<String, dynamic> json) =>
    _$CategoryTrendImpl(
      category: json['category'] as String,
      regretRate: (json['regretRate'] as num).toDouble(),
      transactionCount: (json['transactionCount'] as num).toInt(),
      trend: $enumDecode(_$TrendDirectionEnumMap, json['trend']),
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$$CategoryTrendImplToJson(_$CategoryTrendImpl instance) =>
    <String, dynamic>{
      'category': instance.category,
      'regretRate': instance.regretRate,
      'transactionCount': instance.transactionCount,
      'trend': _$TrendDirectionEnumMap[instance.trend]!,
      'icon': instance.icon,
    };

const _$TrendDirectionEnumMap = {
  TrendDirection.improving: 'improving',
  TrendDirection.steady: 'steady',
  TrendDirection.worsening: 'worsening',
};

_$BehavioralInsightsImpl _$$BehavioralInsightsImplFromJson(
        Map<String, dynamic> json) =>
    _$BehavioralInsightsImpl(
      mood: $enumDecode(_$FinancialMoodEnumMap, json['mood']),
      worthItPercentage: (json['worthItPercentage'] as num).toDouble(),
      worthItCount: (json['worthItCount'] as num).toInt(),
      previousMonthWorthItCount:
          (json['previousMonthWorthItCount'] as num).toInt(),
      impulseeTrends: (json['impulseeTrends'] as List<dynamic>)
          .map((e) => CategoryTrend.fromJson(e as Map<String, dynamic>))
          .toList(),
      budgetTrends: (json['budgetTrends'] as List<dynamic>?)
              ?.map(
                  (e) => BudgetTrendInsight.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BudgetTrendInsight>[],
      moodDescription: json['moodDescription'] as String?,
    );

Map<String, dynamic> _$$BehavioralInsightsImplToJson(
        _$BehavioralInsightsImpl instance) =>
    <String, dynamic>{
      'mood': _$FinancialMoodEnumMap[instance.mood]!,
      'worthItPercentage': instance.worthItPercentage,
      'worthItCount': instance.worthItCount,
      'previousMonthWorthItCount': instance.previousMonthWorthItCount,
      'impulseeTrends': instance.impulseeTrends,
      'budgetTrends': instance.budgetTrends,
      'moodDescription': instance.moodDescription,
    };

const _$FinancialMoodEnumMap = {
  FinancialMood.confident: 'confident',
  FinancialMood.balanced: 'balanced',
  FinancialMood.cautious: 'cautious',
  FinancialMood.impulsive: 'impulsive',
};

_$BudgetTrendInsightImpl _$$BudgetTrendInsightImplFromJson(
        Map<String, dynamic> json) =>
    _$BudgetTrendInsightImpl(
      category: json['category'] as String,
      hasBudget: json['hasBudget'] as bool,
      currencyCode: json['currencyCode'] as String,
      months: (json['months'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      currentMonthSpend: (json['currentMonthSpend'] as num).toDouble(),
      currentMonthPercentUsed:
          (json['currentMonthPercentUsed'] as num?)?.toDouble(),
      insightLabel: json['insightLabel'] as String,
      nudge: json['nudge'] as String?,
    );

Map<String, dynamic> _$$BudgetTrendInsightImplToJson(
        _$BudgetTrendInsightImpl instance) =>
    <String, dynamic>{
      'category': instance.category,
      'hasBudget': instance.hasBudget,
      'currencyCode': instance.currencyCode,
      'months': instance.months,
      'currentMonthSpend': instance.currentMonthSpend,
      'currentMonthPercentUsed': instance.currentMonthPercentUsed,
      'insightLabel': instance.insightLabel,
      'nudge': instance.nudge,
    };
