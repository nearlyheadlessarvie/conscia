using System.Security.Claims;

namespace Conscia.Api.Middleware;

public class SubscriptionTierMiddleware
{
    private readonly RequestDelegate _next;

    public SubscriptionTierMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        var endpoint = context.GetEndpoint();
        var requiresPremium = endpoint?.Metadata.GetMetadata<RequirePremiumAttribute>() is not null;

        if (requiresPremium)
        {
            if (context.User.Identity?.IsAuthenticated != true)
            {
                context.Response.StatusCode = 401;
                await context.Response.WriteAsJsonAsync(new { error = "Authentication required" });
                return;
            }

            var tier = context.User.FindFirstValue("tier");
            if (!string.Equals(tier, "Premium", StringComparison.OrdinalIgnoreCase))
            {
                context.Response.StatusCode = 403;
                await context.Response.WriteAsJsonAsync(new { error = "Premium subscription required" });
                return;
            }
        }

        await _next(context);
    }
}
