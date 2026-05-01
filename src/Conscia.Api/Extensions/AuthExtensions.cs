using System.Security.Claims;

namespace Conscia.Api.Extensions;

public static class AuthExtensions
{
    public static Guid GetUserId(this ClaimsPrincipal user)
    {
        var sub = user.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? user.FindFirstValue("sub")
            ?? throw new UnauthorizedAccessException("User ID claim not found");

        return Guid.Parse(sub);
    }

    public static string GetEmail(this ClaimsPrincipal user) =>
        user.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

    public static string GetTier(this ClaimsPrincipal user) =>
        user.FindFirstValue("tier") ?? "Free";

    public static bool IsPremium(this ClaimsPrincipal user) =>
        string.Equals(GetTier(user), "Premium", StringComparison.OrdinalIgnoreCase);
}
