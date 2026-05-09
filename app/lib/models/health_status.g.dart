// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HealthStatusImpl _$$HealthStatusImplFromJson(Map<String, dynamic> json) =>
    _$HealthStatusImpl(
      status: json['status'] as String,
      totalDuration: json['totalDuration'] as String,
      checks: (json['checks'] as List<dynamic>?)
              ?.map((e) => HealthCheck.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$HealthStatusImplToJson(_$HealthStatusImpl instance) =>
    <String, dynamic>{
      'status': instance.status,
      'totalDuration': instance.totalDuration,
      'checks': instance.checks,
    };

_$HealthCheckImpl _$$HealthCheckImplFromJson(Map<String, dynamic> json) =>
    _$HealthCheckImpl(
      name: json['name'] as String,
      status: json['status'] as String,
      duration: json['duration'] as String,
      exception: json['exception'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$HealthCheckImplToJson(_$HealthCheckImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'status': instance.status,
      'duration': instance.duration,
      'exception': instance.exception,
      'data': instance.data,
    };
