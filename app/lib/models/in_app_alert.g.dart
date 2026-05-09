// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'in_app_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InAppAlertImpl _$$InAppAlertImplFromJson(Map<String, dynamic> json) =>
    _$InAppAlertImpl(
      id: json['id'] as String,
      triggerName: json['triggerName'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$InAppAlertImplToJson(_$InAppAlertImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'triggerName': instance.triggerName,
      'title': instance.title,
      'message': instance.message,
      'createdAt': instance.createdAt.toIso8601String(),
    };
