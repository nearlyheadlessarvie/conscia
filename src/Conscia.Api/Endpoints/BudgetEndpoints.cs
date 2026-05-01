using Conscia.Api.Extensions;
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
            IValidator<CreateBudgetDto> validator) =>
        {
            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            var userId = ctx.User.GetUserId();
            var budget = await svc.CreateAsync(userId, dto.Category, dto.MonthlyLimit, dto.CurrencyCode, ctx.RequestAborted);
            return Results.Created($"/api/v1/budgets/{budget.Id}", new
            {
                budget.Id,
                budget.UserId,
                budget.Category,
                budget.MonthlyLimit,
                budget.CurrentSpend,
                budget.CurrencyCode,
                budget.PercentUsed,
                budget.IsOverBudget
            });
        }).WithName("CreateBudget");

        group.MapGet("/", async (HttpContext ctx, IBudgetService svc) =>
        {
            var userId = ctx.User.GetUserId();
            var budgets = await svc.ListByUserAsync(userId, ctx.RequestAborted);
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
            var budget = await svc.GetByIdAsync(userId, id, ctx.RequestAborted);
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
