using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface IAppleServerNotificationVerifier
{
    Task<AppleServerNotification> VerifyAndDecodeAsync(string signedPayload, CancellationToken ct = default);
}
