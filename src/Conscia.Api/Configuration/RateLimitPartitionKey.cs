using System.Security.Claims;

namespace Conscia.Api.Configuration;

public static class RateLimitPartitionKey
{
    public static string ForRequest(HttpContext context, string policyName)
    {
        var userId = context.User.FindFirstValue(ClaimTypes.NameIdentifier) ??
            context.User.FindFirstValue("sub");
        if (!string.IsNullOrWhiteSpace(userId))
        {
            return $"{policyName}:user:{userId}";
        }

        return $"{policyName}:ip:{ResolveClientIp(context)}";
    }

    private static string ResolveClientIp(HttpContext context)
    {
        var forwardedFor = context.Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(forwardedFor))
        {
            var firstForwardedIp = forwardedFor.Split(',', 2)[0].Trim();
            if (!string.IsNullOrWhiteSpace(firstForwardedIp))
            {
                return firstForwardedIp;
            }
        }

        return context.Connection.RemoteIpAddress?.ToString() ?? "unknown";
    }
}
