using Conscia.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public class NoopPushNotificationSender : IPushNotificationSender
{
    private readonly ILogger<NoopPushNotificationSender> _logger;

    public NoopPushNotificationSender(ILogger<NoopPushNotificationSender> logger)
    {
        _logger = logger;
    }

    public Task SendToUserAsync(
        Guid userId,
        string title,
        string body,
        string? route,
        CancellationToken ct = default)
    {
        _logger.LogInformation(
            "Push sender is not configured. Skipping push to user {UserId}: {Title} ({Route})",
            userId,
            title,
            route);
        return Task.CompletedTask;
    }
}
