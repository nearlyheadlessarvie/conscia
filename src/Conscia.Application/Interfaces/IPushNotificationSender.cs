namespace Conscia.Application.Interfaces;

public interface IPushNotificationSender
{
    Task SendToUserAsync(
        Guid userId,
        string title,
        string body,
        string? route,
        CancellationToken ct = default);
}
