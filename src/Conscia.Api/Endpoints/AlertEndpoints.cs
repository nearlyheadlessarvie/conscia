using Conscia.Api.Extensions;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class AlertEndpoints
{
    public static RouteGroupBuilder MapAlertEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/alerts")
            .RequireAuthorization()
            .WithTags("Alerts");

        group.MapGet("/", async (HttpContext ctx, IInAppAlertRepository repo) =>
        {
            var userId = ctx.User.GetUserId();
            var alerts = await repo.GetByUserAsync(userId, ct: ctx.RequestAborted);
            return Results.Ok(alerts.Select(a => new
            {
                a.Id,
                a.TriggerName,
                a.Title,
                a.Message,
                a.CreatedAt
            }));
        }).WithName("ListAlerts");

        return group;
    }
}
