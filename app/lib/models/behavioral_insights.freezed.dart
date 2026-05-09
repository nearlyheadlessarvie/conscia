// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'behavioral_insights.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CategoryTrend _$CategoryTrendFromJson(Map<String, dynamic> json) {
  return _CategoryTrend.fromJson(json);
}

/// @nodoc
mixin _$CategoryTrend {
  String get category => throw _privateConstructorUsedError;
  double get regretRate => throw _privateConstructorUsedError;
  int get transactionCount => throw _privateConstructorUsedError;
  TrendDirection get trend => throw _privateConstructorUsedError;
  String? get icon => throw _privateConstructorUsedError;

  /// Serializes this CategoryTrend to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CategoryTrend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CategoryTrendCopyWith<CategoryTrend> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CategoryTrendCopyWith<$Res> {
  factory $CategoryTrendCopyWith(
          CategoryTrend value, $Res Function(CategoryTrend) then) =
      _$CategoryTrendCopyWithImpl<$Res, CategoryTrend>;
  @useResult
  $Res call(
      {String category,
      double regretRate,
      int transactionCount,
      TrendDirection trend,
      String? icon});
}

/// @nodoc
class _$CategoryTrendCopyWithImpl<$Res, $Val extends CategoryTrend>
    implements $CategoryTrendCopyWith<$Res> {
  _$CategoryTrendCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CategoryTrend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? regretRate = null,
    Object? transactionCount = null,
    Object? trend = null,
    Object? icon = freezed,
  }) {
    return _then(_value.copyWith(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      regretRate: null == regretRate
          ? _value.regretRate
          : regretRate // ignore: cast_nullable_to_non_nullable
              as double,
      transactionCount: null == transactionCount
          ? _value.transactionCount
          : transactionCount // ignore: cast_nullable_to_non_nullable
              as int,
      trend: null == trend
          ? _value.trend
          : trend // ignore: cast_nullable_to_non_nullable
              as TrendDirection,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CategoryTrendImplCopyWith<$Res>
    implements $CategoryTrendCopyWith<$Res> {
  factory _$$CategoryTrendImplCopyWith(
          _$CategoryTrendImpl value, $Res Function(_$CategoryTrendImpl) then) =
      __$$CategoryTrendImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String category,
      double regretRate,
      int transactionCount,
      TrendDirection trend,
      String? icon});
}

/// @nodoc
class __$$CategoryTrendImplCopyWithImpl<$Res>
    extends _$CategoryTrendCopyWithImpl<$Res, _$CategoryTrendImpl>
    implements _$$CategoryTrendImplCopyWith<$Res> {
  __$$CategoryTrendImplCopyWithImpl(
      _$CategoryTrendImpl _value, $Res Function(_$CategoryTrendImpl) _then)
      : super(_value, _then);

  /// Create a copy of CategoryTrend
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? regretRate = null,
    Object? transactionCount = null,
    Object? trend = null,
    Object? icon = freezed,
  }) {
    return _then(_$CategoryTrendImpl(
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      regretRate: null == regretRate
          ? _value.regretRate
          : regretRate // ignore: cast_nullable_to_non_nullable
              as double,
      transactionCount: null == transactionCount
          ? _value.transactionCount
          : transactionCount // ignore: cast_nullable_to_non_nullable
              as int,
      trend: null == trend
          ? _value.trend
          : trend // ignore: cast_nullable_to_non_nullable
              as TrendDirection,
      icon: freezed == icon
          ? _value.icon
          : icon // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CategoryTrendImpl implements _CategoryTrend {
  const _$CategoryTrendImpl(
      {required this.category,
      required this.regretRate,
      required this.transactionCount,
      required this.trend,
      this.icon});

  factory _$CategoryTrendImpl.fromJson(Map<String, dynamic> json) =>
      _$$CategoryTrendImplFromJson(json);

  @override
  final String category;
  @override
  final double regretRate;
  @override
  final int transactionCount;
  @override
  final TrendDirection trend;
  @override
  final String? icon;

  @override
  String toString() {
    return 'CategoryTrend(category: $category, regretRate: $regretRate, transactionCount: $transactionCount, trend: $trend, icon: $icon)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CategoryTrendImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.regretRate, regretRate) ||
                other.regretRate == regretRate) &&
            (identical(other.transactionCount, transactionCount) ||
                other.transactionCount == transactionCount) &&
            (identical(other.trend, trend) || other.trend == trend) &&
            (identical(other.icon, icon) || other.icon == icon));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, category, regretRate, transactionCount, trend, icon);

  /// Create a copy of CategoryTrend
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CategoryTrendImplCopyWith<_$CategoryTrendImpl> get copyWith =>
      __$$CategoryTrendImplCopyWithImpl<_$CategoryTrendImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CategoryTrendImplToJson(
      this,
    );
  }
}

abstract class _CategoryTrend implements CategoryTrend {
  const factory _CategoryTrend(
      {required final String category,
      required final double regretRate,
      required final int transactionCount,
      required final TrendDirection trend,
      final String? icon}) = _$CategoryTrendImpl;

  factory _CategoryTrend.fromJson(Map<String, dynamic> json) =
      _$CategoryTrendImpl.fromJson;

  @override
  String get category;
  @override
  double get regretRate;
  @override
  int get transactionCount;
  @override
  TrendDirection get trend;
  @override
  String? get icon;

  /// Create a copy of CategoryTrend
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CategoryTrendImplCopyWith<_$CategoryTrendImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BehavioralInsights _$BehavioralInsightsFromJson(Map<String, dynamic> json) {
  return _BehavioralInsights.fromJson(json);
}

/// @nodoc
mixin _$BehavioralInsights {
  FinancialMood get mood => throw _privateConstructorUsedError;
  double get worthItPercentage => throw _privateConstructorUsedError;
  int get worthItCount => throw _privateConstructorUsedError;
  int get previousMonthWorthItCount => throw _privateConstructorUsedError;
  List<CategoryTrend> get impulseeTrends => throw _privateConstructorUsedError;
  String? get moodDescription => throw _privateConstructorUsedError;

  /// Serializes this BehavioralInsights to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BehavioralInsights
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BehavioralInsightsCopyWith<BehavioralInsights> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BehavioralInsightsCopyWith<$Res> {
  factory $BehavioralInsightsCopyWith(
          BehavioralInsights value, $Res Function(BehavioralInsights) then) =
      _$BehavioralInsightsCopyWithImpl<$Res, BehavioralInsights>;
  @useResult
  $Res call(
      {FinancialMood mood,
      double worthItPercentage,
      int worthItCount,
      int previousMonthWorthItCount,
      List<CategoryTrend> impulseeTrends,
      String? moodDescription});
}

/// @nodoc
class _$BehavioralInsightsCopyWithImpl<$Res, $Val extends BehavioralInsights>
    implements $BehavioralInsightsCopyWith<$Res> {
  _$BehavioralInsightsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BehavioralInsights
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mood = null,
    Object? worthItPercentage = null,
    Object? worthItCount = null,
    Object? previousMonthWorthItCount = null,
    Object? impulseeTrends = null,
    Object? moodDescription = freezed,
  }) {
    return _then(_value.copyWith(
      mood: null == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as FinancialMood,
      worthItPercentage: null == worthItPercentage
          ? _value.worthItPercentage
          : worthItPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      worthItCount: null == worthItCount
          ? _value.worthItCount
          : worthItCount // ignore: cast_nullable_to_non_nullable
              as int,
      previousMonthWorthItCount: null == previousMonthWorthItCount
          ? _value.previousMonthWorthItCount
          : previousMonthWorthItCount // ignore: cast_nullable_to_non_nullable
              as int,
      impulseeTrends: null == impulseeTrends
          ? _value.impulseeTrends
          : impulseeTrends // ignore: cast_nullable_to_non_nullable
              as List<CategoryTrend>,
      moodDescription: freezed == moodDescription
          ? _value.moodDescription
          : moodDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BehavioralInsightsImplCopyWith<$Res>
    implements $BehavioralInsightsCopyWith<$Res> {
  factory _$$BehavioralInsightsImplCopyWith(_$BehavioralInsightsImpl value,
          $Res Function(_$BehavioralInsightsImpl) then) =
      __$$BehavioralInsightsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {FinancialMood mood,
      double worthItPercentage,
      int worthItCount,
      int previousMonthWorthItCount,
      List<CategoryTrend> impulseeTrends,
      String? moodDescription});
}

/// @nodoc
class __$$BehavioralInsightsImplCopyWithImpl<$Res>
    extends _$BehavioralInsightsCopyWithImpl<$Res, _$BehavioralInsightsImpl>
    implements _$$BehavioralInsightsImplCopyWith<$Res> {
  __$$BehavioralInsightsImplCopyWithImpl(_$BehavioralInsightsImpl _value,
      $Res Function(_$BehavioralInsightsImpl) _then)
      : super(_value, _then);

  /// Create a copy of BehavioralInsights
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mood = null,
    Object? worthItPercentage = null,
    Object? worthItCount = null,
    Object? previousMonthWorthItCount = null,
    Object? impulseeTrends = null,
    Object? moodDescription = freezed,
  }) {
    return _then(_$BehavioralInsightsImpl(
      mood: null == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as FinancialMood,
      worthItPercentage: null == worthItPercentage
          ? _value.worthItPercentage
          : worthItPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      worthItCount: null == worthItCount
          ? _value.worthItCount
          : worthItCount // ignore: cast_nullable_to_non_nullable
              as int,
      previousMonthWorthItCount: null == previousMonthWorthItCount
          ? _value.previousMonthWorthItCount
          : previousMonthWorthItCount // ignore: cast_nullable_to_non_nullable
              as int,
      impulseeTrends: null == impulseeTrends
          ? _value._impulseeTrends
          : impulseeTrends // ignore: cast_nullable_to_non_nullable
              as List<CategoryTrend>,
      moodDescription: freezed == moodDescription
          ? _value.moodDescription
          : moodDescription // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BehavioralInsightsImpl implements _BehavioralInsights {
  const _$BehavioralInsightsImpl(
      {required this.mood,
      required this.worthItPercentage,
      required this.worthItCount,
      required this.previousMonthWorthItCount,
      required final List<CategoryTrend> impulseeTrends,
      this.moodDescription})
      : _impulseeTrends = impulseeTrends;

  factory _$BehavioralInsightsImpl.fromJson(Map<String, dynamic> json) =>
      _$$BehavioralInsightsImplFromJson(json);

  @override
  final FinancialMood mood;
  @override
  final double worthItPercentage;
  @override
  final int worthItCount;
  @override
  final int previousMonthWorthItCount;
  final List<CategoryTrend> _impulseeTrends;
  @override
  List<CategoryTrend> get impulseeTrends {
    if (_impulseeTrends is EqualUnmodifiableListView) return _impulseeTrends;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_impulseeTrends);
  }

  @override
  final String? moodDescription;

  @override
  String toString() {
    return 'BehavioralInsights(mood: $mood, worthItPercentage: $worthItPercentage, worthItCount: $worthItCount, previousMonthWorthItCount: $previousMonthWorthItCount, impulseeTrends: $impulseeTrends, moodDescription: $moodDescription)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BehavioralInsightsImpl &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.worthItPercentage, worthItPercentage) ||
                other.worthItPercentage == worthItPercentage) &&
            (identical(other.worthItCount, worthItCount) ||
                other.worthItCount == worthItCount) &&
            (identical(other.previousMonthWorthItCount,
                    previousMonthWorthItCount) ||
                other.previousMonthWorthItCount == previousMonthWorthItCount) &&
            const DeepCollectionEquality()
                .equals(other._impulseeTrends, _impulseeTrends) &&
            (identical(other.moodDescription, moodDescription) ||
                other.moodDescription == moodDescription));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      mood,
      worthItPercentage,
      worthItCount,
      previousMonthWorthItCount,
      const DeepCollectionEquality().hash(_impulseeTrends),
      moodDescription);

  /// Create a copy of BehavioralInsights
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BehavioralInsightsImplCopyWith<_$BehavioralInsightsImpl> get copyWith =>
      __$$BehavioralInsightsImplCopyWithImpl<_$BehavioralInsightsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BehavioralInsightsImplToJson(
      this,
    );
  }
}

abstract class _BehavioralInsights implements BehavioralInsights {
  const factory _BehavioralInsights(
      {required final FinancialMood mood,
      required final double worthItPercentage,
      required final int worthItCount,
      required final int previousMonthWorthItCount,
      required final List<CategoryTrend> impulseeTrends,
      final String? moodDescription}) = _$BehavioralInsightsImpl;

  factory _BehavioralInsights.fromJson(Map<String, dynamic> json) =
      _$BehavioralInsightsImpl.fromJson;

  @override
  FinancialMood get mood;
  @override
  double get worthItPercentage;
  @override
  int get worthItCount;
  @override
  int get previousMonthWorthItCount;
  @override
  List<CategoryTrend> get impulseeTrends;
  @override
  String? get moodDescription;

  /// Create a copy of BehavioralInsights
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BehavioralInsightsImplCopyWith<_$BehavioralInsightsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
