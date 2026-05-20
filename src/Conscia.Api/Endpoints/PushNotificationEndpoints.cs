using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Api.Endpoints;

public static class PushNotificationEndpoints
{
    public static RouteGroupBuilder MapPushNotificationEndpoints(this IEndpointRouteBuilder routes, ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/push")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Push Notifications");

        group.MapPost("/device-tokens", async (
            HttpContext ctx,
            RegisterDeviceTokenRequest request,
            IPushDeviceTokenRepository repository) =>
        {
            if (string.IsNullOrWhiteSpace(request.Token))
            {
                return Results.BadRequest(new { error = "Device token is required." });
            }

            var now = DateTime.UtcNow;
            await repository.UpsertAsync(new PushDeviceToken
            {
                UserId = ctx.User.GetUserId(),
                Token = request.Token.Trim(),
                Platform = NormalizePlatform(request.Platform),
                CreatedAt = now,
                UpdatedAt = now,
                LastSeenAt = now,
                IsActive = true
            }, ctx.RequestAborted);

            return Results.NoContent();
        }).WithName("RegisterPushDeviceToken");

        return group;
    }

    private static string NormalizePlatform(string? platform)
    {
        var normalized = platform?.Trim().ToLowerInvariant();
        return string.IsNullOrWhiteSpace(normalized) ? "unknown" : normalized;
    }

    public sealed record RegisterDeviceTokenRequest(string Token, string? Platform);
}
