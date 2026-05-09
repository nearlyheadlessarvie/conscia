// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ai_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AIResponse _$AIResponseFromJson(Map<String, dynamic> json) {
  return _AIResponse.fromJson(json);
}

/// @nodoc
mixin _$AIResponse {
  String get devilMessage => throw _privateConstructorUsedError;
  String get angelMessage => throw _privateConstructorUsedError;
  String get neutralMessage => throw _privateConstructorUsedError;
  BudgetContext? get budgetContext => throw _privateConstructorUsedError;

  /// Serializes this AIResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AIResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AIResponseCopyWith<AIResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AIResponseCopyWith<$Res> {
  factory $AIResponseCopyWith(
          AIResponse value, $Res Function(AIResponse) then) =
      _$AIResponseCopyWithImpl<$Res, AIResponse>;
  @useResult
  $Res call(
      {String devilMessage,
      String angelMessage,
      String neutralMessage,
      BudgetContext? budgetContext});

  $BudgetContextCopyWith<$Res>? get budgetContext;
}

/// @nodoc
class _$AIResponseCopyWithImpl<$Res, $Val extends AIResponse>
    implements $AIResponseCopyWith<$Res> {
  _$AIResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AIResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? devilMessage = null,
    Object? angelMessage = null,
    Object? neutralMessage = null,
    Object? budgetContext = freezed,
  }) {
    return _then(_value.copyWith(
      devilMessage: null == devilMessage
          ? _value.devilMessage
          : devilMessage // ignore: cast_nullable_to_non_nullable
              as String,
      angelMessage: null == angelMessage
          ? _value.angelMessage
          : angelMessage // ignore: cast_nullable_to_non_nullable
              as String,
      neutralMessage: null == neutralMessage
          ? _value.neutralMessage
          : neutralMessage // ignore: cast_nullable_to_non_nullable
              as String,
      budgetContext: freezed == budgetContext
          ? _value.budgetContext
          : budgetContext // ignore: cast_nullable_to_non_nullable
              as BudgetContext?,
    ) as $Val);
  }

  /// Create a copy of AIResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BudgetContextCopyWith<$Res>? get budgetContext {
    if (_value.budgetContext == null) {
      return null;
    }

    return $BudgetContextCopyWith<$Res>(_value.budgetContext!, (value) {
      return _then(_value.copyWith(budgetContext: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AIResponseImplCopyWith<$Res>
    implements $AIResponseCopyWith<$Res> {
  factory _$$AIResponseImplCopyWith(
          _$AIResponseImpl value, $Res Function(_$AIResponseImpl) then) =
      __$$AIResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String devilMessage,
      String angelMessage,
      String neutralMessage,
      BudgetContext? budgetContext});

  @override
  $BudgetContextCopyWith<$Res>? get budgetContext;
}

/// @nodoc
class __$$AIResponseImplCopyWithImpl<$Res>
    extends _$AIResponseCopyWithImpl<$Res, _$AIResponseImpl>
    implements _$$AIResponseImplCopyWith<$Res> {
  __$$AIResponseImplCopyWithImpl(
      _$AIResponseImpl _value, $Res Function(_$AIResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of AIResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? devilMessage = null,
    Object? angelMessage = null,
    Object? neutralMessage = null,
    Object? budgetContext = freezed,
  }) {
    return _then(_$AIResponseImpl(
      devilMessage: null == devilMessage
          ? _value.devilMessage
          : devilMessage // ignore: cast_nullable_to_non_nullable
              as String,
      angelMessage: null == angelMessage
          ? _value.angelMessage
          : angelMessage // ignore: cast_nullable_to_non_nullable
              as String,
      neutralMessage: null == neutralMessage
          ? _value.neutralMessage
          : neutralMessage // ignore: cast_nullable_to_non_nullable
              as String,
      budgetContext: freezed == budgetContext
          ? _value.budgetContext
          : budgetContext // ignore: cast_nullable_to_non_nullable
              as BudgetContext?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AIResponseImpl implements _AIResponse {
  const _$AIResponseImpl(
      {required this.devilMessage,
      required this.angelMessage,
      required this.neutralMessage,
      this.budgetContext});

  factory _$AIResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AIResponseImplFromJson(json);

  @override
  final String devilMessage;
  @override
  final String angelMessage;
  @override
  final String neutralMessage;
  @override
  final BudgetContext? budgetContext;

  @override
  String toString() {
    return 'AIResponse(devilMessage: $devilMessage, angelMessage: $angelMessage, neutralMessage: $neutralMessage, budgetContext: $budgetContext)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AIResponseImpl &&
            (identical(other.devilMessage, devilMessage) ||
                other.devilMessage == devilMessage) &&
            (identical(other.angelMessage, angelMessage) ||
                other.angelMessage == angelMessage) &&
            (identical(other.neutralMessage, neutralMessage) ||
                other.neutralMessage == neutralMessage) &&
            (identical(other.budgetContext, budgetContext) ||
                other.budgetContext == budgetContext));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, devilMessage, angelMessage, neutralMessage, budgetContext);

  /// Create a copy of AIResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AIResponseImplCopyWith<_$AIResponseImpl> get copyWith =>
      __$$AIResponseImplCopyWithImpl<_$AIResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AIResponseImplToJson(
      this,
    );
  }
}

abstract class _AIResponse implements AIResponse {
  const factory _AIResponse(
      {required final String devilMessage,
      required final String angelMessage,
      required final String neutralMessage,
      final BudgetContext? budgetContext}) = _$AIResponseImpl;

  factory _AIResponse.fromJson(Map<String, dynamic> json) =
      _$AIResponseImpl.fromJson;

  @override
  String get devilMessage;
  @override
  String get angelMessage;
  @override
  String get neutralMessage;
  @override
  BudgetContext? get budgetContext;

  /// Create a copy of AIResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AIResponseImplCopyWith<_$AIResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BudgetContext _$BudgetContextFromJson(Map<String, dynamic> json) {
  return _BudgetContext.fromJson(json);
}

/// @nodoc
mixin _$BudgetContext {
  String get category => throw _privateConstructorUsedError;
  double get monthlyLimit => throw _privateConstructorUsedError;
  double get currentSpend => throw _privateConstructorUsedError;
  double get percentUsed => throw _privateConstructorUsedError;
  String get currencyCode => throw _privateConstructorUsedError;

  /// Serializes this BudgetContext to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BudgetContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BudgetContextCopyWith<BudgetContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BudgetContextCopyWith<$Res> {
  factory $BudgetContextCopyWith(
          BudgetContext value, $Res Function(BudgetContext) then) =
      _$BudgetContextCopyWithImpl<$Res, BudgetContext>;
  @useResult
  $Res call(
      {String category,
      double monthlyLimit,
      double currentSpend,
      double percentUsed,
      String currencyCode});
}

/// @nodoc
class _$BudgetContextCopyWithImpl<$Res, $Val extends BudgetContext>
    implements $BudgetContextCopyWith<$Res> {
  _$BudgetContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BudgetContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? monthlyLimit = null,
    Object? currentSpend = null,
    Object? percentUsed = null,
    Object? currencyCode = null,
  }) {
    return _then(_value.copyWith(
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
      percentUsed: null == percentUsed
          ? _value.percentUsed
          : percentUsed // ignore: cast_nullable_to_non_nullable
              as double,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BudgetContextImplCopyWith<$Res>
    implements $BudgetContextCopyWith<$Res> {
  factory _$$BudgetContextImplCopyWith(
          _$BudgetContextImpl value, $Res Function(_$BudgetContextImpl) then) =
      __$$BudgetContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String category,
      double monthlyLimit,
      double currentSpend,
      double percentUsed,
      String currencyCode});
}

/// @nodoc
class __$$BudgetContextImplCopyWithImpl<$Res>
    extends _$BudgetContextCopyWithImpl<$Res, _$BudgetContextImpl>
    implements _$$BudgetContextImplCopyWith<$Res> {
  __$$BudgetContextImplCopyWithImpl(
      _$BudgetContextImpl _value, $Res Function(_$BudgetContextImpl) _then)
      : super(_value, _then);

  /// Create a copy of BudgetContext
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? category = null,
    Object? monthlyLimit = null,
    Object? currentSpend = null,
    Object? percentUsed = null,
    Object? currencyCode = null,
  }) {
    return _then(_$BudgetContextImpl(
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
      percentUsed: null == percentUsed
          ? _value.percentUsed
          : percentUsed // ignore: cast_nullable_to_non_nullable
              as double,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BudgetContextImpl implements _BudgetContext {
  const _$BudgetContextImpl(
      {required this.category,
      required this.monthlyLimit,
      required this.currentSpend,
      required this.percentUsed,
      required this.currencyCode});

  factory _$BudgetContextImpl.fromJson(Map<String, dynamic> json) =>
      _$$BudgetContextImplFromJson(json);

  @override
  final String category;
  @override
  final double monthlyLimit;
  @override
  final double currentSpend;
  @override
  final double percentUsed;
  @override
  final String currencyCode;

  @override
  String toString() {
    return 'BudgetContext(category: $category, monthlyLimit: $monthlyLimit, currentSpend: $currentSpend, percentUsed: $percentUsed, currencyCode: $currencyCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BudgetContextImpl &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.monthlyLimit, monthlyLimit) ||
                other.monthlyLimit == monthlyLimit) &&
            (identical(other.currentSpend, currentSpend) ||
                other.currentSpend == currentSpend) &&
            (identical(other.percentUsed, percentUsed) ||
                other.percentUsed == percentUsed) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, category, monthlyLimit,
      currentSpend, percentUsed, currencyCode);

  /// Create a copy of BudgetContext
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BudgetContextImplCopyWith<_$BudgetContextImpl> get copyWith =>
      __$$BudgetContextImplCopyWithImpl<_$BudgetContextImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BudgetContextImplToJson(
      this,
    );
  }
}

abstract class _BudgetContext implements BudgetContext {
  const factory _BudgetContext(
      {required final String category,
      required final double monthlyLimit,
      required final double currentSpend,
      required final double percentUsed,
      required final String currencyCode}) = _$BudgetContextImpl;

  factory _BudgetContext.fromJson(Map<String, dynamic> json) =
      _$BudgetContextImpl.fromJson;

  @override
  String get category;
  @override
  double get monthlyLimit;
  @override
  double get currentSpend;
  @override
  double get percentUsed;
  @override
  String get currencyCode;

  /// Create a copy of BudgetContext
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BudgetContextImplCopyWith<_$BudgetContextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
