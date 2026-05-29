using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;

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
            return Results.Ok(items.Select(ToResponse));
        }).WithName("ListAlerts");

        group.MapPost("/", async (HttpContext ctx, IAlertService alerts, CreateAlertRequest request) =>
        {
            if (string.IsNullOrWhiteSpace(request.Id)
                || string.IsNullOrWhiteSpace(request.Type)
                || string.IsNullOrWhiteSpace(request.Title)
                || string.IsNullOrWhiteSpace(request.Message))
            {
                return Results.BadRequest(new { error = "Alert id, type, title, and message are required." });
            }

            var userId = ctx.User.GetUserId();
            var alert = new InAppAlert
            {
                AlertKey = request.Id.Trim(),
                TriggerName = request.Type.Trim(),
                Title = request.Title.Trim(),
                Message = request.Message.Trim(),
                Priority = request.Priority,
                ActionLabel = request.ActionLabel,
                ActionRoute = request.ActionRoute,
                TransactionId = request.TransactionId,
                Category = request.Category,
                Counterparty = request.Counterparty,
                CreatedAt = request.CreatedAt ?? DateTime.UtcNow
            };

            var created = await alerts.CreateAlertAsync(userId, alert, ctx.RequestAborted);
            return Results.Ok(ToResponse(created));
        }).WithName("CreateAlert");

        group.MapPost("/{id}/dismiss", async (HttpContext ctx, IAlertService alerts, string id) =>
        {
            var alertId = Uri.UnescapeDataString(id);
            if (string.IsNullOrWhiteSpace(alertId))
            {
                return Results.BadRequest(new { error = "Alert id is required." });
            }

            var userId = ctx.User.GetUserId();
            await alerts.DismissAlertAsync(userId, alertId, ctx.RequestAborted);
            return Results.NoContent();
        }).WithName("DismissAlert");

        return group;
    }

    private static object ToResponse(InAppAlert a) => new
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
    };

    public sealed record CreateAlertRequest(
        string? Id,
        string? Type,
        string? Title,
        string? Message,
        int Priority,
        string? ActionLabel,
        string? ActionRoute,
        Guid? TransactionId,
        string? Category,
        string? Counterparty,
        DateTime? CreatedAt);
}
