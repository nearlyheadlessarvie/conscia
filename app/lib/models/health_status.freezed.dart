// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HealthStatus _$HealthStatusFromJson(Map<String, dynamic> json) {
  return _HealthStatus.fromJson(json);
}

/// @nodoc
mixin _$HealthStatus {
  String get status => throw _privateConstructorUsedError;
  String get totalDuration => throw _privateConstructorUsedError;
  List<HealthCheck> get checks => throw _privateConstructorUsedError;

  /// Serializes this HealthStatus to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HealthStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthStatusCopyWith<HealthStatus> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthStatusCopyWith<$Res> {
  factory $HealthStatusCopyWith(
          HealthStatus value, $Res Function(HealthStatus) then) =
      _$HealthStatusCopyWithImpl<$Res, HealthStatus>;
  @useResult
  $Res call({String status, String totalDuration, List<HealthCheck> checks});
}

/// @nodoc
class _$HealthStatusCopyWithImpl<$Res, $Val extends HealthStatus>
    implements $HealthStatusCopyWith<$Res> {
  _$HealthStatusCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HealthStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? totalDuration = null,
    Object? checks = null,
  }) {
    return _then(_value.copyWith(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      totalDuration: null == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as String,
      checks: null == checks
          ? _value.checks
          : checks // ignore: cast_nullable_to_non_nullable
              as List<HealthCheck>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HealthStatusImplCopyWith<$Res>
    implements $HealthStatusCopyWith<$Res> {
  factory _$$HealthStatusImplCopyWith(
          _$HealthStatusImpl value, $Res Function(_$HealthStatusImpl) then) =
      __$$HealthStatusImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String status, String totalDuration, List<HealthCheck> checks});
}

/// @nodoc
class __$$HealthStatusImplCopyWithImpl<$Res>
    extends _$HealthStatusCopyWithImpl<$Res, _$HealthStatusImpl>
    implements _$$HealthStatusImplCopyWith<$Res> {
  __$$HealthStatusImplCopyWithImpl(
      _$HealthStatusImpl _value, $Res Function(_$HealthStatusImpl) _then)
      : super(_value, _then);

  /// Create a copy of HealthStatus
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? totalDuration = null,
    Object? checks = null,
  }) {
    return _then(_$HealthStatusImpl(
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      totalDuration: null == totalDuration
          ? _value.totalDuration
          : totalDuration // ignore: cast_nullable_to_non_nullable
              as String,
      checks: null == checks
          ? _value._checks
          : checks // ignore: cast_nullable_to_non_nullable
              as List<HealthCheck>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HealthStatusImpl implements _HealthStatus {
  const _$HealthStatusImpl(
      {required this.status,
      required this.totalDuration,
      final List<HealthCheck> checks = const []})
      : _checks = checks;

  factory _$HealthStatusImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthStatusImplFromJson(json);

  @override
  final String status;
  @override
  final String totalDuration;
  final List<HealthCheck> _checks;
  @override
  @JsonKey()
  List<HealthCheck> get checks {
    if (_checks is EqualUnmodifiableListView) return _checks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_checks);
  }

  @override
  String toString() {
    return 'HealthStatus(status: $status, totalDuration: $totalDuration, checks: $checks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthStatusImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration) &&
            const DeepCollectionEquality().equals(other._checks, _checks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, status, totalDuration,
      const DeepCollectionEquality().hash(_checks));

  /// Create a copy of HealthStatus
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthStatusImplCopyWith<_$HealthStatusImpl> get copyWith =>
      __$$HealthStatusImplCopyWithImpl<_$HealthStatusImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthStatusImplToJson(
      this,
    );
  }
}

abstract class _HealthStatus implements HealthStatus {
  const factory _HealthStatus(
      {required final String status,
      required final String totalDuration,
      final List<HealthCheck> checks}) = _$HealthStatusImpl;

  factory _HealthStatus.fromJson(Map<String, dynamic> json) =
      _$HealthStatusImpl.fromJson;

  @override
  String get status;
  @override
  String get totalDuration;
  @override
  List<HealthCheck> get checks;

  /// Create a copy of HealthStatus
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthStatusImplCopyWith<_$HealthStatusImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HealthCheck _$HealthCheckFromJson(Map<String, dynamic> json) {
  return _HealthCheck.fromJson(json);
}

/// @nodoc
mixin _$HealthCheck {
  String get name => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  String get duration => throw _privateConstructorUsedError;
  String? get exception => throw _privateConstructorUsedError;
  Map<String, dynamic>? get data => throw _privateConstructorUsedError;

  /// Serializes this HealthCheck to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HealthCheck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HealthCheckCopyWith<HealthCheck> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthCheckCopyWith<$Res> {
  factory $HealthCheckCopyWith(
          HealthCheck value, $Res Function(HealthCheck) then) =
      _$HealthCheckCopyWithImpl<$Res, HealthCheck>;
  @useResult
  $Res call(
      {String name,
      String status,
      String duration,
      String? exception,
      Map<String, dynamic>? data});
}

/// @nodoc
class _$HealthCheckCopyWithImpl<$Res, $Val extends HealthCheck>
    implements $HealthCheckCopyWith<$Res> {
  _$HealthCheckCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HealthCheck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? status = null,
    Object? duration = null,
    Object? exception = freezed,
    Object? data = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String,
      exception: freezed == exception
          ? _value.exception
          : exception // ignore: cast_nullable_to_non_nullable
              as String?,
      data: freezed == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HealthCheckImplCopyWith<$Res>
    implements $HealthCheckCopyWith<$Res> {
  factory _$$HealthCheckImplCopyWith(
          _$HealthCheckImpl value, $Res Function(_$HealthCheckImpl) then) =
      __$$HealthCheckImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String status,
      String duration,
      String? exception,
      Map<String, dynamic>? data});
}

/// @nodoc
class __$$HealthCheckImplCopyWithImpl<$Res>
    extends _$HealthCheckCopyWithImpl<$Res, _$HealthCheckImpl>
    implements _$$HealthCheckImplCopyWith<$Res> {
  __$$HealthCheckImplCopyWithImpl(
      _$HealthCheckImpl _value, $Res Function(_$HealthCheckImpl) _then)
      : super(_value, _then);

  /// Create a copy of HealthCheck
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? status = null,
    Object? duration = null,
    Object? exception = freezed,
    Object? data = freezed,
  }) {
    return _then(_$HealthCheckImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String,
      exception: freezed == exception
          ? _value.exception
          : exception // ignore: cast_nullable_to_non_nullable
              as String?,
      data: freezed == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HealthCheckImpl implements _HealthCheck {
  const _$HealthCheckImpl(
      {required this.name,
      required this.status,
      required this.duration,
      this.exception,
      final Map<String, dynamic>? data})
      : _data = data;

  factory _$HealthCheckImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthCheckImplFromJson(json);

  @override
  final String name;
  @override
  final String status;
  @override
  final String duration;
  @override
  final String? exception;
  final Map<String, dynamic>? _data;
  @override
  Map<String, dynamic>? get data {
    final value = _data;
    if (value == null) return null;
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'HealthCheck(name: $name, status: $status, duration: $duration, exception: $exception, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthCheckImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.exception, exception) ||
                other.exception == exception) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, status, duration,
      exception, const DeepCollectionEquality().hash(_data));

  /// Create a copy of HealthCheck
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthCheckImplCopyWith<_$HealthCheckImpl> get copyWith =>
      __$$HealthCheckImplCopyWithImpl<_$HealthCheckImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthCheckImplToJson(
      this,
    );
  }
}

abstract class _HealthCheck implements HealthCheck {
  const factory _HealthCheck(
      {required final String name,
      required final String status,
      required final String duration,
      final String? exception,
      final Map<String, dynamic>? data}) = _$HealthCheckImpl;

  factory _HealthCheck.fromJson(Map<String, dynamic> json) =
      _$HealthCheckImpl.fromJson;

  @override
  String get name;
  @override
  String get status;
  @override
  String get duration;
  @override
  String? get exception;
  @override
  Map<String, dynamic>? get data;

  /// Create a copy of HealthCheck
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HealthCheckImplCopyWith<_$HealthCheckImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
