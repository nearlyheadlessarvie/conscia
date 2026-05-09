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
      'moodDescription': instance.moodDescription,
    };

const _$FinancialMoodEnumMap = {
  FinancialMood.confident: 'confident',
  FinancialMood.balanced: 'balanced',
  FinancialMood.cautious: 'cautious',
  FinancialMood.impulsive: 'impulsive',
};
