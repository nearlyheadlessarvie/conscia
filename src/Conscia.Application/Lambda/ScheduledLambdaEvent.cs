namespace Conscia.Application.Lambda;

/// <summary>
/// Marker payload for scheduled EventBridge Lambda invocations.
/// Unknown event fields are ignored because these processors do not use them.
/// </summary>
public sealed record ScheduledLambdaEvent;
