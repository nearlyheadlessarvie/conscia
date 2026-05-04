using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Api.Extensions;

namespace Conscia.Api.Endpoints;

public static class InsightsEndpoints
{
    public static RouteGroupBuilder MapInsightsEndpoints(this IEndpointRouteBuilder app)
    {
        var insightsGroup = app.MapGroup("/api/v1/insights")
            .RequireAuthorization()
            .WithTags("Insights");

        insightsGroup.MapGet("/behavioral", GetBehavioralInsights)
            .WithName("GetBehavioralInsights")
            .WithDescription("Get user's behavioral insights for dashboard")
            .Produces<BehavioralInsights>(StatusCodes.Status200OK)
            .Produces<BehavioralInsights>(StatusCodes.Status204NoContent)            
            .Produces(StatusCodes.Status500InternalServerError);

        return insightsGroup;
    }

    private static async Task<IResult> GetBehavioralInsights(
        HttpContext ctx,
        IBehavioralInsightsService insightsService,
        CancellationToken ct)
    {
        try
        {
            var userId = ctx.User.GetUserId();
            var insights = await insightsService.GetBehavioralInsightsAsync(userId, ct);
            return insights != null ? Results.Ok(insights) : Results.NoContent();
        }
        catch (Exception ex)
        {
            // Log the exception
            return Results.Problem(
                title: "Failed to retrieve behavioral insights",
                detail: ex.Message,
                statusCode: StatusCodes.Status500InternalServerError);
        }
    }
}