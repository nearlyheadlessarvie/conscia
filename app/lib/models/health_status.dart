import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_status.freezed.dart';
part 'health_status.g.dart';

@freezed
class HealthStatus with _$HealthStatus {
  const factory HealthStatus({
    required String status,
    required String totalDuration,
    @Default([]) List<HealthCheck> checks,
  }) = _HealthStatus;

  factory HealthStatus.fromJson(Map<String, dynamic> json) =>
      _$HealthStatusFromJson(json);
}

@freezed
class HealthCheck with _$HealthCheck {
  const factory HealthCheck({
    required String name,
    required String status,
    required String duration,
    String? exception,
    Map<String, dynamic>? data,
  }) = _HealthCheck;

  factory HealthCheck.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckFromJson(json);
}
