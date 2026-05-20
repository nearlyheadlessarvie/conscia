using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class AlertEndpoints
{
    public static RouteGroupBuilder MapAlertEndpoints(this IEndpointRouteBuilder routes, ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/alerts")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Alerts");

        group.MapGet("/", async (HttpContext ctx, IAlertService alerts) =>
        {
            var userId = ctx.User.GetUserId();
            var items = await alerts.ListAlertsAsync(userId, ctx.RequestAborted);
            return Results.Ok(items.Select(a => new
            {
                id = string.IsNullOrWhiteSpace(a.AlertKey) ? a.Id.ToString() : a.AlertKey,
                type = a.TriggerName,
                a.Title,
                a.Message,
                a.Priority,
                a.ActionLabel,
                a.ActionRoute,
                transactionId = a.TransactionId,
                a.Category,
                a.Counterparty,
                a.CreatedAt
            }));
        }).WithName("ListAlerts");

        return group;
    }
}
