using Conscia.Api.Extensions;
using Conscia.Application.Constants;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class ConscienceJourneyEndpoints
{
    public static RouteGroupBuilder MapConscienceJourneyEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/conscience-journey")
            .RequireAuthorization()
            .WithTags("Conscience Journey");

        group.MapGet("/", async (HttpContext ctx, IConscienceJourneyService service, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var summary = await service.GetJourneyAsync(userId, ct);
            return Results.Ok(summary);
        }).WithName("GetConscienceJourney");

        group.MapPost("/events", async (
            HttpContext ctx,
            RecordConscienceEventRequest request,
            IConscienceJourneyService service,
            CancellationToken ct) =>
        {
            if (!ConscienceJourneyRules.SupportedEventTypes.Contains(request.EventType, StringComparer.Ordinal))
                return Results.BadRequest(new { error = "Unsupported conscience journey event type." });

            if (string.IsNullOrWhiteSpace(request.SourceId))
                return Results.BadRequest(new { error = "sourceId is required." });

            var userId = ctx.User.GetUserId();
            var update = await service.RecordEventAsync(
                userId,
                request.EventType,
                request.SourceId,
                ct);

            return Results.Ok(update);
        }).WithName("RecordConscienceJourneyEvent");

        return group;
    }
}
