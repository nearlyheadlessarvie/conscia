using Conscia.Api.Extensions;
using Conscia.Application.Constants;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using FluentValidation;

namespace Conscia.Api.Endpoints;

public static class BudgetEndpoints
{
    public static RouteGroupBuilder MapBudgetEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/budgets")
            .RequireAuthorization()
            .WithTags("Budgets");

        group.MapPost("/", async (
            HttpContext ctx,
            CreateBudgetDto dto,
            IBudgetService svc,
            IUserService userSvc,
            ISubscriptionService subSvc,
            IValidator<CreateBudgetDto> validator) =>
        {
            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            var userId = ctx.User.GetUserId();

            var isPremium = await subSvc.IsPremiumAsync(userId, ctx.RequestAborted);
            if (!isPremium)
            {
                var user = await userSvc.GetByIdAsync(userId, ctx.RequestAborted);
                var categoryLimit = user?.HasCompletedOnboarding == false
                    ? 5
                    : FreemiumLimits.FreeBudgetCategories;
                var existing = await svc.ListByUserAsync(userId, ctx.RequestAborted);
                if (existing.Count >= categoryLimit)
                    return Results.Json(
                        new { error = $"Free tier limit: {categoryLimit} budget categories", upgradeRequired = true },
                        statusCode: 403);
            }

            var budget = await svc.CreateAsync(userId, dto.Category, dto.MonthlyLimit, dto.CurrencyCode, ctx.RequestAborted);
            var status = await svc.GetStatusByIdAsync(userId, budget.Id, ct: ctx.RequestAborted);
            return Results.Created($"/api/v1/budgets/{budget.Id}", new
            {
                budget.Id,
                budget.UserId,
                budget.Category,
                budget.MonthlyLimit,
                CurrentSpend = status?.CurrentSpend ?? 0m,
                budget.CurrencyCode,
                PercentUsed = status?.PercentUsed ?? 0m,
                IsOverBudget = status?.IsOverBudget ?? false
            });
        }).WithName("CreateBudget");

        group.MapGet("/", async (HttpContext ctx, IBudgetService svc) =>
        {
            var userId = ctx.User.GetUserId();
            var budgets = await svc.ListStatusesByUserAsync(userId, ct: ctx.RequestAborted);
            return Results.Ok(budgets.Select(b => new
            {
                b.Id,
                b.Category,
                b.MonthlyLimit,
                b.CurrentSpend,
                b.CurrencyCode,
                b.PercentUsed,
                b.IsOverBudget
            }));
        }).WithName("ListBudgets");

        group.MapGet("/{id:guid}", async (HttpContext ctx, Guid id, IBudgetService svc) =>
        {
            var userId = ctx.User.GetUserId();
            var budget = await svc.GetStatusByIdAsync(userId, id, ct: ctx.RequestAborted);
            if (budget is null) return Results.NotFound();

            return Results.Ok(new
            {
                budget.Id,
                budget.Category,
                budget.MonthlyLimit,
                budget.CurrentSpend,
                budget.CurrencyCode,
                budget.PercentUsed,
                budget.IsOverBudget
            });
        }).WithName("GetBudget");

        group.MapPut("/{id:guid}", async (
            HttpContext ctx,
            Guid id,
            UpdateBudgetDto dto,
            IBudgetService svc,
            IValidator<UpdateBudgetDto> validator) =>
        {
            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            var userId = ctx.User.GetUserId();
            var budget = await svc.UpdateAsync(userId, id, dto.MonthlyLimit, dto.Category, ctx.RequestAborted);
            var status = await svc.GetStatusByIdAsync(userId, budget.Id, ct: ctx.RequestAborted);
            return Results.Ok(new
            {
                budget.Id,
                budget.Category,
                budget.MonthlyLimit,
                CurrentSpend = status?.CurrentSpend ?? 0m,
                budget.CurrencyCode,
                PercentUsed = status?.PercentUsed ?? 0m,
                IsOverBudget = status?.IsOverBudget ?? false
            });
        }).WithName("UpdateBudget");

        group.MapDelete("/{id:guid}", async (HttpContext ctx, Guid id, IBudgetService svc) =>
        {
            var userId = ctx.User.GetUserId();
            await svc.DeleteAsync(userId, id, ctx.RequestAborted);
            return Results.NoContent();
        }).WithName("DeleteBudget");

        return group;
    }
}
