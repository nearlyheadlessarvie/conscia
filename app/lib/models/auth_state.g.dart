// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnauthenticatedImpl _$$UnauthenticatedImplFromJson(
        Map<String, dynamic> json) =>
    _$UnauthenticatedImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$UnauthenticatedImplToJson(
        _$UnauthenticatedImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$AuthenticatedImpl _$$AuthenticatedImplFromJson(Map<String, dynamic> json) =>
    _$AuthenticatedImpl(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: json['userId'] as String,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$AuthenticatedImplToJson(_$AuthenticatedImpl instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'userId': instance.userId,
      'runtimeType': instance.$type,
    };
