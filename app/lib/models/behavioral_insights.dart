import 'package:freezed_annotation/freezed_annotation.dart';

part 'behavioral_insights.freezed.dart';
part 'behavioral_insights.g.dart';

enum FinancialMood {
  @JsonValue('confident')
  confident,
  @JsonValue('balanced')
  balanced,
  @JsonValue('cautious')
  cautious,
  @JsonValue('impulsive')
  impulsive,
}

enum TrendDirection {
  @JsonValue('improving')
  improving,
  @JsonValue('steady')
  steady,
  @JsonValue('worsening')
  worsening,
}

@freezed
class CategoryTrend with _$CategoryTrend {
  const factory CategoryTrend({
    required String category,
    required double regretRate,
    required int transactionCount,
    required TrendDirection trend,
    String? icon,
  }) = _CategoryTrend;

  factory CategoryTrend.fromJson(Map<String, dynamic> json) =>
      _$CategoryTrendFromJson(json);
}

@freezed
class BehavioralInsights with _$BehavioralInsights {
  const factory BehavioralInsights({
    required FinancialMood mood,
    required double worthItPercentage,
    required int worthItCount,
    required int previousMonthWorthItCount,
    required List<CategoryTrend> impulseeTrends,
    String? moodDescription,
  }) = _BehavioralInsights;

  factory BehavioralInsights.fromJson(Map<String, dynamic> json) =>
      _$BehavioralInsightsFromJson(json);
}
