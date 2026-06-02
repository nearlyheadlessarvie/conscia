namespace Conscia.Application.Interfaces;

public interface ICaptchaVerifier
{
    Task<bool> VerifyAsync(CaptchaVerificationRequest request, CancellationToken ct = default);
}

public sealed record CaptchaVerificationRequest(
    string? Token,
    string? SiteKey,
    string ExpectedAction,
    string? UserIpAddress,
    string? UserAgent);
