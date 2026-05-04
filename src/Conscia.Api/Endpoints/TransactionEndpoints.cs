using System.Diagnostics;
using Conscia.Api.Extensions;
using Conscia.Api.Telemetry;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Enums;
using FluentValidation;

namespace Conscia.Api.Endpoints;

public static class TransactionEndpoints
{
    public static RouteGroupBuilder MapTransactionEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/transactions")
            .RequireAuthorization()
            .WithTags("Transactions");

        group.MapPost("/", async (
            HttpContext ctx,
            CreateTransactionDto dto,
            ITransactionService svc,
            IValidator<CreateTransactionDto> validator) =>
        {
            using var activity = ConsciaActivitySources.Transactions.StartActivity("CreateTransaction");

            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            activity?.SetTag("transaction.type", dto.Type.ToString());
            activity?.SetTag("transaction.currency", dto.CurrencyCode);
            activity?.SetTag("transaction.category", dto.Category);

            var userId = ctx.User.GetUserId();
            var txn = await svc.CreateAsync(userId, dto, ctx.RequestAborted);
            ConsciaMetrics.TransactionsCreated.Add(1);
            return Results.Created($"/api/v1/transactions/{txn.Id}", new
            {
                txn.Id,
                txn.UserId,
                Type = txn.Type.ToString(),
                Amount = txn.Amount.Amount,
                CurrencyCode = txn.Amount.CurrencyCode,
                txn.Category,
                txn.Merchant,
                txn.Date,
                txn.CreatedAt
            });
        }).WithName("CreateTransaction");

        group.MapGet("/", async (
            HttpContext ctx,
            ITransactionService svc,
            int page = 1,
            int pageSize = 20,
            string? category = null) =>
        {
            var userId = ctx.User.GetUserId();
            var result = await svc.ListAsync(userId, page, pageSize, category, ctx.RequestAborted);
            return Results.Ok(new
            {
                result.Page,
                result.PageSize,
                result.TotalCount,
                result.HasMore,
                Items = result.Items.Select(t => new
                {
                    t.Id,
                    Type = t.Type.ToString(),
                    Amount = t.Amount.Amount,
                    CurrencyCode = t.Amount.CurrencyCode,
                    t.Category,
                    t.Merchant,
                    t.Date,
                    RegretLevel = t.RegretLevel?.ToString()
                })
            });
        }).WithName("ListTransactions");

        group.MapGet("/{id:guid}", async (HttpContext ctx, Guid id, ITransactionService svc) =>
        {            
            var txn = await svc.GetByIdAsync(id, ctx.RequestAborted);
            if (txn is null) return Results.NotFound();

            return Results.Ok(new
            {
                txn.Id,
                Type = txn.Type.ToString(),
                Amount = txn.Amount.Amount,
                CurrencyCode = txn.Amount.CurrencyCode,
                txn.Category,
                txn.Merchant,
                txn.Date,
                Location = txn.Location is not null ? new
                {
                    txn.Location.Latitude,
                    txn.Location.Longitude,
                    txn.Location.MerchantName
                } : null,
                RegretLevel = txn.RegretLevel?.ToString(),
                txn.CreatedAt
            });
        }).WithName("GetTransaction");

        group.MapPut("/{id:guid}", async (
            HttpContext ctx,
            Guid id,
            UpdateTransactionDto dto,
            ITransactionService svc,
            IValidator<UpdateTransactionDto> validator) =>
        {
            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());
            
            var txn = await svc.UpdateAsync(id, dto, ctx.RequestAborted);
            return Results.Ok(new
            {
                txn.Id,
                Type = txn.Type.ToString(),
                Amount = txn.Amount.Amount,
                CurrencyCode = txn.Amount.CurrencyCode,
                txn.Category,
                txn.Merchant,
                txn.Date
            });
        }).WithName("UpdateTransaction");

        group.MapDelete("/{id:guid}", async (HttpContext ctx, Guid id, ITransactionService svc) =>
        {
            await svc.DeleteAsync(id, ctx.RequestAborted);
            return Results.NoContent();
        }).WithName("DeleteTransaction");

        group.MapPost("/{id:guid}/regret", async (
            HttpContext ctx,
            Guid id,
            RegretFeedbackDto dto,
            ITransactionService svc) =>
        {
            if (!Enum.IsDefined(dto.Level))
                return Results.BadRequest(new { error = "Invalid regret level" });

            await svc.UpdateRegretLevelAsync(id, dto.Level, ctx.RequestAborted);
            ConsciaMetrics.RegretFeedbackSubmitted.Add(1);
            return Results.NoContent();
        }).WithName("UpdateRegretLevel");

        return group;
    }
}
