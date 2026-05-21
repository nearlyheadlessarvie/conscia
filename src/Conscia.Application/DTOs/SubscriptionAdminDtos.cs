namespace Conscia.Application.DTOs;

public sealed record GrantLifetimePremiumRequest(string GrantedBy, string? Note);

public sealed record ProvisionReviewerAccountRequest(
    string Email,
    string TemporaryPassword,
    bool GrantLifetimePremium,
    string? Note);

public sealed record AdminUserLookupResponse(
    Guid UserId,
    string Email,
    bool IsLifetime,
    string Source,
    bool IsActive);
