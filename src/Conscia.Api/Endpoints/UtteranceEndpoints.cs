using Conscia.Api.Extensions;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;

namespace Conscia.Api.Endpoints;

public static class UtteranceEndpoints
{
    public static RouteGroupBuilder MapUtteranceEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/transactions")
            .RequireAuthorization()
            .WithTags("Transactions");

        group.MapPost("/parse-utterance", async (
            HttpContext ctx,
            ParseUtteranceRequest req,
            IAIService aiService,
            CancellationToken ct) =>
        {
            if (!ctx.User.IsPremium())
                return Results.Forbid();

            if (string.IsNullOrWhiteSpace(req.Transcript))
                return Results.BadRequest(new { error = "Transcript is required." });

            var result = await aiService.ParseUtteranceAsync(req.Transcript, ct);
            return Results.Ok(result);
        })
        .WithName("ParseUtterance")
        .Produces<UtteranceParseResult>(StatusCodes.Status200OK)
        .Produces(StatusCodes.Status403Forbidden)
        .Produces(StatusCodes.Status400BadRequest)
        .Produces(StatusCodes.Status500InternalServerError);

        return group;
    }
}

public record ParseUtteranceRequest(string Transcript);
