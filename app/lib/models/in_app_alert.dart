import 'package:freezed_annotation/freezed_annotation.dart';

part 'in_app_alert.freezed.dart';
part 'in_app_alert.g.dart';

@freezed
class InAppAlert with _$InAppAlert {
  const factory InAppAlert({
    required String id,
    required String triggerName,
    required String title,
    required String message,
    required DateTime createdAt,
  }) = _InAppAlert;

  factory InAppAlert.fromJson(Map<String, dynamic> json) =>
      _$InAppAlertFromJson(json);
}
