using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.Interfaces;
using Microsoft.AspNetCore.RateLimiting;

namespace Conscia.Api.Endpoints;

public static class SubscriptionEndpoints
{
    public static RouteGroupBuilder MapSubscriptionEndpoints(this IEndpointRouteBuilder routes, ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/subscriptions")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Subscriptions");

        group.MapGet("/status", async (HttpContext ctx, ISubscriptionService svc) =>
        {
            var userId = ctx.User.GetUserId();
            var status = await svc.GetEffectiveStatusAsync(userId, ctx.RequestAborted);
            return Results.Ok(new
            {
                tier = status.Tier.ToString(),
                platform = status.Platform?.ToString(),
                isActive = status.IsActive,
                isLifetime = status.IsLifetime,
                source = status.Source,
                expiresAt = status.ExpiresAt
            });
        }).WithName("GetSubscriptionStatus");

        group.MapPost("/verify/ios", async (HttpContext ctx, VerifyReceiptRequest req, ISubscriptionService svc) =>
        {
            if (string.IsNullOrWhiteSpace(req.Token))
                return Results.BadRequest(new { error = "Receipt data is required" });

            try
            {
                var userId = ctx.User.GetUserId();
                var sub = await svc.VerifyiOSReceiptAsync(userId, req.Token, ctx.RequestAborted);
                return Results.Ok(new
                {
                    tier = sub.Tier.ToString(),
                    isActive = sub.IsActive,
                    expiresAt = sub.ExpiresAt
                });
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
        })
        .RequireRateLimiting("iap-verify")
        .WithName("VerifyiOSReceipt");

        group.MapPost("/verify/android", async (HttpContext ctx, VerifyReceiptRequest req, ISubscriptionService svc) =>
        {
            if (string.IsNullOrWhiteSpace(req.Token))
                return Results.BadRequest(new { error = "Purchase token is required" });

            try
            {
                var userId = ctx.User.GetUserId();
                var sub = await svc.VerifyAndroidTokenAsync(userId, req.Token, ctx.RequestAborted);
                return Results.Ok(new
                {
                    tier = sub.Tier.ToString(),
                    isActive = sub.IsActive,
                    expiresAt = sub.ExpiresAt
                });
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
        })
        .RequireRateLimiting("iap-verify")
        .WithName("VerifyAndroidToken");

        return group;
    }
}

public record VerifyReceiptRequest(string Token);
