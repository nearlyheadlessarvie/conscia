// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Transaction _$TransactionFromJson(Map<String, dynamic> json) {
  return _Transaction.fromJson(json);
}

/// @nodoc
mixin _$Transaction {
  String get id => throw _privateConstructorUsedError;
  TransactionType get type => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get currencyCode => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'counterparty', readValue: _readCounterparty)
  String? get counterparty => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'placeName', readValue: _readPlaceName)
  String? get location => throw _privateConstructorUsedError;
  int get regretLevel => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  double? get exchangeRateToBase => throw _privateConstructorUsedError;

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TransactionCopyWith<Transaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TransactionCopyWith<$Res> {
  factory $TransactionCopyWith(
          Transaction value, $Res Function(Transaction) then) =
      _$TransactionCopyWithImpl<$Res, Transaction>;
  @useResult
  $Res call(
      {String id,
      TransactionType type,
      double amount,
      String currencyCode,
      String category,
      @JsonKey(name: 'counterparty', readValue: _readCounterparty)
      String? counterparty,
      DateTime date,
      @JsonKey(name: 'placeName', readValue: _readPlaceName) String? location,
      int regretLevel,
      String? notes,
      DateTime createdAt,
      double? exchangeRateToBase});
}

/// @nodoc
class _$TransactionCopyWithImpl<$Res, $Val extends Transaction>
    implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? currencyCode = null,
    Object? category = null,
    Object? counterparty = freezed,
    Object? date = null,
    Object? location = freezed,
    Object? regretLevel = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? exchangeRateToBase = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      counterparty: freezed == counterparty
          ? _value.counterparty
          : counterparty // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      regretLevel: null == regretLevel
          ? _value.regretLevel
          : regretLevel // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      exchangeRateToBase: freezed == exchangeRateToBase
          ? _value.exchangeRateToBase
          : exchangeRateToBase // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TransactionImplCopyWith<$Res>
    implements $TransactionCopyWith<$Res> {
  factory _$$TransactionImplCopyWith(
          _$TransactionImpl value, $Res Function(_$TransactionImpl) then) =
      __$$TransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      TransactionType type,
      double amount,
      String currencyCode,
      String category,
      @JsonKey(name: 'counterparty', readValue: _readCounterparty)
      String? counterparty,
      DateTime date,
      @JsonKey(name: 'placeName', readValue: _readPlaceName) String? location,
      int regretLevel,
      String? notes,
      DateTime createdAt,
      double? exchangeRateToBase});
}

/// @nodoc
class __$$TransactionImplCopyWithImpl<$Res>
    extends _$TransactionCopyWithImpl<$Res, _$TransactionImpl>
    implements _$$TransactionImplCopyWith<$Res> {
  __$$TransactionImplCopyWithImpl(
      _$TransactionImpl _value, $Res Function(_$TransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? currencyCode = null,
    Object? category = null,
    Object? counterparty = freezed,
    Object? date = null,
    Object? location = freezed,
    Object? regretLevel = null,
    Object? notes = freezed,
    Object? createdAt = null,
    Object? exchangeRateToBase = freezed,
  }) {
    return _then(_$TransactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TransactionType,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      currencyCode: null == currencyCode
          ? _value.currencyCode
          : currencyCode // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      counterparty: freezed == counterparty
          ? _value.counterparty
          : counterparty // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      regretLevel: null == regretLevel
          ? _value.regretLevel
          : regretLevel // ignore: cast_nullable_to_non_nullable
              as int,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      exchangeRateToBase: freezed == exchangeRateToBase
          ? _value.exchangeRateToBase
          : exchangeRateToBase // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TransactionImpl implements _Transaction {
  const _$TransactionImpl(
      {required this.id,
      required this.type,
      required this.amount,
      required this.currencyCode,
      required this.category,
      @JsonKey(name: 'counterparty', readValue: _readCounterparty)
      this.counterparty,
      required this.date,
      @JsonKey(name: 'placeName', readValue: _readPlaceName) this.location,
      this.regretLevel = 0,
      this.notes,
      required this.createdAt,
      this.exchangeRateToBase});

  factory _$TransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TransactionImplFromJson(json);

  @override
  final String id;
  @override
  final TransactionType type;
  @override
  final double amount;
  @override
  final String currencyCode;
  @override
  final String category;
  @override
  @JsonKey(name: 'counterparty', readValue: _readCounterparty)
  final String? counterparty;
  @override
  final DateTime date;
  @override
  @JsonKey(name: 'placeName', readValue: _readPlaceName)
  final String? location;
  @override
  @JsonKey()
  final int regretLevel;
  @override
  final String? notes;
  @override
  final DateTime createdAt;
  @override
  final double? exchangeRateToBase;

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, currencyCode: $currencyCode, category: $category, counterparty: $counterparty, date: $date, location: $location, regretLevel: $regretLevel, notes: $notes, createdAt: $createdAt, exchangeRateToBase: $exchangeRateToBase)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currencyCode, currencyCode) ||
                other.currencyCode == currencyCode) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.counterparty, counterparty) ||
                other.counterparty == counterparty) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.regretLevel, regretLevel) ||
                other.regretLevel == regretLevel) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.exchangeRateToBase, exchangeRateToBase) ||
                other.exchangeRateToBase == exchangeRateToBase));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      amount,
      currencyCode,
      category,
      counterparty,
      date,
      location,
      regretLevel,
      notes,
      createdAt,
      exchangeRateToBase);

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      __$$TransactionImplCopyWithImpl<_$TransactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TransactionImplToJson(
      this,
    );
  }
}

abstract class _Transaction implements Transaction {
  const factory _Transaction(
      {required final String id,
      required final TransactionType type,
      required final double amount,
      required final String currencyCode,
      required final String category,
      @JsonKey(name: 'counterparty', readValue: _readCounterparty)
      final String? counterparty,
      required final DateTime date,
      @JsonKey(name: 'placeName', readValue: _readPlaceName)
      final String? location,
      final int regretLevel,
      final String? notes,
      required final DateTime createdAt,
      final double? exchangeRateToBase}) = _$TransactionImpl;

  factory _Transaction.fromJson(Map<String, dynamic> json) =
      _$TransactionImpl.fromJson;

  @override
  String get id;
  @override
  TransactionType get type;
  @override
  double get amount;
  @override
  String get currencyCode;
  @override
  String get category;
  @override
  @JsonKey(name: 'counterparty', readValue: _readCounterparty)
  String? get counterparty;
  @override
  DateTime get date;
  @override
  @JsonKey(name: 'placeName', readValue: _readPlaceName)
  String? get location;
  @override
  int get regretLevel;
  @override
  String? get notes;
  @override
  DateTime get createdAt;
  @override
  double? get exchangeRateToBase;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TransactionImplCopyWith<_$TransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
