// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Budget _$BudgetFromJson(Map<String, dynamic> json) {
  return _Budget.fromJson(json);
}

/// @nodoc
mixin _$Budget {
  String get id => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  double get monthlyLimit => throw _privateConstructorUsedError;
  double get currentSpend => throw _privateConstructorUsedError;
  String get currencyCode => throw _privateConstructorUsedError;
  double get percentUsed => throw _privateConstructorUsedError;
  bool get isOverBudget => throw _privateConstructorUsedError;

  /// Serializes this Budget to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetCopyWith<Budget> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetCopyWith<$Res> {
  factory $BudgetCopyWith(Budget value, $Res Function(Budget) then) =
      _$BudgetCopyWithImpl<$Res, Budget>;
  @useResult
  $Res call(
      {String id,
      String category,
      double monthlyLimit,
      double currentSpend,
      String currencyCode,
      double percentUsed,
      bool isOverBudget});
}

/// @nodoc
class _$BudgetCopyWithImpl<$Res, $Val extends Budget>
    implements $BudgetCopyWith<$Res> {
  _$BudgetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? category = null,
    Object? monthlyLimit = null,
    Object? currentSpend = null,
    Object? currencyCode = null,
    Object? percentUsed = null,
    Object? isOverBudget = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      monthlyLimit: null == monthlyLimit
          ? _value.monthlyLimit
          : monthlyLimit // ignore: cast_nullable_to_non_nullable
              as double,
      currentSpend: null == currentSpend
          ? _value.currentSpend
          : currentSpend // ignore: cast_nullable_to_non_nullable
              as double,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      percentUsed: null == percentUsed
          ? _value.percentUsed
          : percentUsed // ignore: cast_nullable_to_non_nullable
              as double,
      isOverBudget: null == isOverBudget
          ? _value.isOverBudget
          : isOverBudget // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BudgetImplCopyWith<$Res> implements $BudgetCopyWith<$Res> {
  factory _$$BudgetImplCopyWith(
          _$BudgetImpl value, $Res Function(_$BudgetImpl) then) =
      __$$BudgetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String category,
      double monthlyLimit,
      double currentSpend,
      String currencyCode,
      double percentUsed,
      bool isOverBudget});
}

/// @nodoc
class __$$BudgetImplCopyWithImpl<$Res>
    extends _$BudgetCopyWithImpl<$Res, _$BudgetImpl>
    implements _$$BudgetImplCopyWith<$Res> {
  __$$BudgetImplCopyWithImpl(
      _$BudgetImpl _value, $Res Function(_$BudgetImpl) _then)
      : super(_value, _then);

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? category = null,
    Object? monthlyLimit = null,
    Object? currentSpend = null,
    Object? currencyCode = null,
    Object? percentUsed = null,
    Object? isOverBudget = null,
  }) {
    return _then(_$BudgetImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      monthlyLimit: null == monthlyLimit
          ? _value.monthlyLimit
          : monthlyLimit // ignore: cast_nullable_to_non_nullable
              as double,
      currentSpend: null == currentSpend
          ? _value.currentSpend
          : currentSpend // ignore: cast_nullable_to_non_nullable
              as double,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      percentUsed: null == percentUsed
          ? _value.percentUsed
          : percentUsed // ignore: cast_nullable_to_non_nullable
              as double,
      isOverBudget: null == isOverBudget
          ? _value.isOverBudget
          : isOverBudget // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BudgetImpl implements _Budget {
  const _$BudgetImpl(
      {required this.id,
      required this.category,
      required this.monthlyLimit,
      required this.currentSpend,
      required this.currencyCode,
      required this.percentUsed,
      required this.isOverBudget});

  factory _$BudgetImpl.fromJson(Map<String, dynamic> json) =>
      _$$BudgetImplFromJson(json);

  @override
  final String id;
  @override
  final String category;
  @override
  final double monthlyLimit;
  @override
  final double currentSpend;
  @override
  final String currencyCode;
  @override
  final double percentUsed;
  @override
  final bool isOverBudget;

  @override
  String toString() {
    return 'Budget(id: $id, category: $category, monthlyLimit: $monthlyLimit, currentSpend: $currentSpend, currencyCode: $currencyCode, percentUsed: $percentUsed, isOverBudget: $isOverBudget)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.monthlyLimit, monthlyLimit) ||
                other.monthlyLimit == monthlyLimit) &&
            (identical(other.currentSpend, currentSpend) ||
                other.currentSpend == currentSpend) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.percentUsed, percentUsed) ||
                other.percentUsed == percentUsed) &&
            (identical(other.isOverBudget, isOverBudget) ||
                other.isOverBudget == isOverBudget));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, category, monthlyLimit,
      currentSpend, currencyCode, percentUsed, isOverBudget);

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetImplCopyWith<_$BudgetImpl> get copyWith =>
      __$$BudgetImplCopyWithImpl<_$BudgetImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BudgetImplToJson(
      this,
    );
  }
}

abstract class _Budget implements Budget {
  const factory _Budget(
      {required final String id,
      required final String category,
      required final double monthlyLimit,
      required final double currentSpend,
      required final String currencyCode,
      required final double percentUsed,
      required final bool isOverBudget}) = _$BudgetImpl;

  factory _Budget.fromJson(Map<String, dynamic> json) = _$BudgetImpl.fromJson;

  @override
  String get id;
  @override
  String get category;
  @override
  double get monthlyLimit;
  @override
  double get currentSpend;
  @override
  String get currencyCode;
  @override
  double get percentUsed;
  @override
  bool get isOverBudget;

  /// Create a copy of Budget
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetImplCopyWith<_$BudgetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
