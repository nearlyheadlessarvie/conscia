import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_status.freezed.dart';
part 'subscription_status.g.dart';

enum SubscriptionTier {
  @JsonValue('free')
  free,
  @JsonValue('premium')
  premium,
}

enum SubscriptionPlatform {
  @JsonValue('ios')
  ios,
  @JsonValue('android')
  android,
  @JsonValue('web')
  web,
}

@freezed
class SubscriptionStatus with _$SubscriptionStatus {
  const factory SubscriptionStatus({
    required SubscriptionTier tier,
    required SubscriptionPlatform platform,
    required bool isActive,
    DateTime? expiresAt,
  }) = _SubscriptionStatus;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionStatusFromJson(json);
}
