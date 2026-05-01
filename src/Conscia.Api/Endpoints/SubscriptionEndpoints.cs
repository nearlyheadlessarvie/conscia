using Conscia.Api.Extensions;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class SubscriptionEndpoints
{
    public static RouteGroupBuilder MapSubscriptionEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/subscriptions")
            .RequireAuthorization()
            .WithTags("Subscriptions");

        group.MapGet("/status", async (HttpContext ctx, ISubscriptionService svc) =>
        {
            var userId = ctx.User.GetUserId();
            var sub = await svc.GetStatusAsync(userId, ctx.RequestAborted);
            return sub is null
                ? Results.Ok(new { tier = "Free", isActive = false })
                : Results.Ok(new
                {
                    tier = sub.Tier.ToString(),
                    platform = sub.Platform.ToString(),
                    isActive = sub.IsActive,
                    expiresAt = sub.ExpiresAt
                });
        }).WithName("GetSubscriptionStatus");

        group.MapPost("/verify/ios", async (HttpContext ctx, VerifyReceiptRequest req, ISubscriptionService svc) =>
        {
            if (string.IsNullOrWhiteSpace(req.Token))
                return Results.BadRequest(new { error = "Receipt data is required" });

            var userId = ctx.User.GetUserId();
            var sub = await svc.VerifyiOSReceiptAsync(userId, req.Token, ctx.RequestAborted);
            return Results.Ok(new
            {
                tier = sub.Tier.ToString(),
                isActive = sub.IsActive,
                expiresAt = sub.ExpiresAt
            });
        }).WithName("VerifyiOSReceipt");

        group.MapPost("/verify/android", async (HttpContext ctx, VerifyReceiptRequest req, ISubscriptionService svc) =>
        {
            if (string.IsNullOrWhiteSpace(req.Token))
                return Results.BadRequest(new { error = "Purchase token is required" });

            var userId = ctx.User.GetUserId();
            var sub = await svc.VerifyAndroidTokenAsync(userId, req.Token, ctx.RequestAborted);
            return Results.Ok(new
            {
                tier = sub.Tier.ToString(),
                isActive = sub.IsActive,
                expiresAt = sub.ExpiresAt
            });
        }).WithName("VerifyAndroidToken");

        return group;
    }
}

public record VerifyReceiptRequest(string Token);
