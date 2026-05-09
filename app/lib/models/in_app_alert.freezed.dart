// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'in_app_alert.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InAppAlert _$InAppAlertFromJson(Map<String, dynamic> json) {
  return _InAppAlert.fromJson(json);
}

/// @nodoc
mixin _$InAppAlert {
  String get id => throw _privateConstructorUsedError;
  String get triggerName => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this InAppAlert to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InAppAlert
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InAppAlertCopyWith<InAppAlert> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InAppAlertCopyWith<$Res> {
  factory $InAppAlertCopyWith(
          InAppAlert value, $Res Function(InAppAlert) then) =
      _$InAppAlertCopyWithImpl<$Res, InAppAlert>;
  @useResult
  $Res call(
      {String id,
      String triggerName,
      String title,
      String message,
      DateTime createdAt});
}

/// @nodoc
class _$InAppAlertCopyWithImpl<$Res, $Val extends InAppAlert>
    implements $InAppAlertCopyWith<$Res> {
  _$InAppAlertCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InAppAlert
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? triggerName = null,
    Object? title = null,
    Object? message = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      triggerName: null == triggerName
          ? _value.triggerName
          : triggerName // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InAppAlertImplCopyWith<$Res>
    implements $InAppAlertCopyWith<$Res> {
  factory _$$InAppAlertImplCopyWith(
          _$InAppAlertImpl value, $Res Function(_$InAppAlertImpl) then) =
      __$$InAppAlertImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String triggerName,
      String title,
      String message,
      DateTime createdAt});
}

/// @nodoc
class __$$InAppAlertImplCopyWithImpl<$Res>
    extends _$InAppAlertCopyWithImpl<$Res, _$InAppAlertImpl>
    implements _$$InAppAlertImplCopyWith<$Res> {
  __$$InAppAlertImplCopyWithImpl(
      _$InAppAlertImpl _value, $Res Function(_$InAppAlertImpl) _then)
      : super(_value, _then);

  /// Create a copy of InAppAlert
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? triggerName = null,
    Object? title = null,
    Object? message = null,
    Object? createdAt = null,
  }) {
    return _then(_$InAppAlertImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      triggerName: null == triggerName
          ? _value.triggerName
          : triggerName // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InAppAlertImpl implements _InAppAlert {
  const _$InAppAlertImpl(
      {required this.id,
      required this.triggerName,
      required this.title,
      required this.message,
      required this.createdAt});

  factory _$InAppAlertImpl.fromJson(Map<String, dynamic> json) =>
      _$$InAppAlertImplFromJson(json);

  @override
  final String id;
  @override
  final String triggerName;
  @override
  final String title;
  @override
  final String message;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'InAppAlert(id: $id, triggerName: $triggerName, title: $title, message: $message, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InAppAlertImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.triggerName, triggerName) ||
                other.triggerName == triggerName) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, triggerName, title, message, createdAt);

  /// Create a copy of InAppAlert
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InAppAlertImplCopyWith<_$InAppAlertImpl> get copyWith =>
      __$$InAppAlertImplCopyWithImpl<_$InAppAlertImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InAppAlertImplToJson(
      this,
    );
  }
}

abstract class _InAppAlert implements InAppAlert {
  const factory _InAppAlert(
      {required final String id,
      required final String triggerName,
      required final String title,
      required final String message,
      required final DateTime createdAt}) = _$InAppAlertImpl;

  factory _InAppAlert.fromJson(Map<String, dynamic> json) =
      _$InAppAlertImpl.fromJson;

  @override
  String get id;
  @override
  String get triggerName;
  @override
  String get title;
  @override
  String get message;
  @override
  DateTime get createdAt;

  /// Create a copy of InAppAlert
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InAppAlertImplCopyWith<_$InAppAlertImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
