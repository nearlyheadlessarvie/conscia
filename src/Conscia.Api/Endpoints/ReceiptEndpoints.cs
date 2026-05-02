using Conscia.Api.Extensions;
using Conscia.Api.Middleware;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class ReceiptEndpoints
{
    public static RouteGroupBuilder MapReceiptEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/receipts")
            .RequireAuthorization()
            .WithTags("Receipts");

        group.MapPost("/scan", async (HttpContext ctx, IReceiptService receiptService) =>
        {
            var userId = ctx.User.GetUserId();
            var result = await receiptService.ScanAsync(userId, ctx.Request.Body, ctx.RequestAborted);
            return Results.Ok(result);
        })
        .WithName("ScanReceipt")
        .WithMetadata(new RequirePremiumAttribute());

        group.MapGet("/{id}", async (string id, HttpContext ctx, IReceiptService receiptService) =>
        {
            if (!Guid.TryParse(id, out var receiptId))
                return Results.BadRequest(new { error = "Invalid receipt ID" });

            var userId = ctx.User.GetUserId();
            var result = await receiptService.GetByIdAsync(userId, receiptId, ctx.RequestAborted);
            return result is null ? Results.NotFound(new { error = "Receipt not found" }) : Results.Ok(result);
        })
        .WithName("GetReceipt")
        .WithMetadata(new RequirePremiumAttribute());

        group.MapPost("/{id}/confirm", async (string id, ConfirmReceiptRequest req, HttpContext ctx, IReceiptService receiptService) =>
        {
            if (!Guid.TryParse(id, out var receiptId))
                return Results.BadRequest(new { error = "Invalid receipt ID" });

            var userId = ctx.User.GetUserId();
            var transaction = await receiptService.ConfirmAsync(userId, receiptId, req, ctx.RequestAborted);
            return Results.Ok(transaction);
        })
        .WithName("ConfirmReceipt")
        .WithMetadata(new RequirePremiumAttribute());

        return group;
    }
}
