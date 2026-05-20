using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Api.Middleware;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class ReceiptEndpoints
{
    public static RouteGroupBuilder MapReceiptEndpoints(this IEndpointRouteBuilder routes, ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/receipts")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Receipts");

        group.MapPost("/scan", async (HttpContext ctx, IReceiptService receiptService) =>
        {
            if (!ctx.Request.HasFormContentType)
                return Results.BadRequest(new { error = "Receipt image is required" });

            var form = await ctx.Request.ReadFormAsync(ctx.RequestAborted);
            var image = form.Files["image"] ?? form.Files.FirstOrDefault();
            if (image is null || image.Length == 0)
                return Results.BadRequest(new { error = "Receipt image is required" });

            var userId = ctx.User.GetUserId();
            await using var stream = image.OpenReadStream();
            try
            {
                var result = await receiptService.ScanAsync(
                    userId,
                    stream,
                    string.IsNullOrWhiteSpace(image.ContentType) ? "image/jpeg" : image.ContentType,
                    ctx.RequestAborted);

                return Results.Ok(result);
            }
            catch (InvalidOperationException ex)
            {
                return Results.Json(
                    new { error = ex.Message },
                    statusCode: StatusCodes.Status503ServiceUnavailable);
            }
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
