using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using FluentValidation;

namespace Conscia.Api.Endpoints;

public static class UserEndpoints
{
    public static RouteGroupBuilder MapUserEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/users")
            .RequireAuthorization()
            .WithTags("Users");

        group.MapGet("/me", async (HttpContext ctx, IUserService svc) =>
        {
            var userId = ctx.User.GetUserId();
            var user = await svc.GetByIdAsync(userId, ctx.RequestAborted);
            return user is null
                ? Results.NotFound()
                : Results.Ok(new
                {
                    user.Id,
                    user.Email,
                    user.PreferredCurrency,
                    user.Locale,
                    user.CreatedAt,
                    user.SpendingPersonality,
                    user.IncomeRange,
                    user.OccupationType,
                    user.HouseholdSize,
                    user.HasCompletedOnboarding,
                });
        }).WithName("GetCurrentUser");

        group.MapPut("/me", async (
            HttpContext ctx,
            UserProfileUpdateDto dto,
            IUserService svc,
            IValidator<UserProfileUpdateDto> validator) =>
        {
            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            var userId = ctx.User.GetUserId();
            var user = await svc.UpdateProfileAsync(userId, dto, ctx.RequestAborted);
            return Results.Ok(new
            {
                user.Id,
                user.Email,
                user.PreferredCurrency,
                user.Locale,
                user.CreatedAt,
                user.SpendingPersonality,
                user.IncomeRange,
                user.OccupationType,
                user.HouseholdSize,
                user.HasCompletedOnboarding,
            });
        }).WithName("UpdateCurrentUser");

        group.MapGet("/me/export", async (
            HttpContext ctx,
            IUserService svc,
            ITransactionService txnSvc,
            IBudgetService budgetSvc) =>
        {
            var userId = ctx.User.GetUserId();
            var ct = ctx.RequestAborted;

            var user = await svc.GetByIdAsync(userId, ct);
            if (user is null) return Results.NotFound();

            var transactions = await txnSvc.ListAsync(userId, 1, 10000, null, ct);
            var budgets = await budgetSvc.ListStatusesByUserAsync(userId, ct: ct);

            return Results.Ok(new
            {
                ExportedAt = DateTime.UtcNow,
                Profile = new
                {
                    user.Id,
                    user.Email,
                    user.PreferredCurrency,
                    user.Locale,
                    user.CreatedAt,
                    user.HasCompletedOnboarding
                },
                Transactions = transactions.Items,
                Budgets = budgets
            });
        }).WithName("ExportUserData");

        group.MapDelete("/me", async (
            HttpContext ctx,
            IUserService svc) =>
        {
            var userId = ctx.User.GetUserId();
            await svc.DeleteAccountAsync(userId, ctx.RequestAborted);
            return Results.NoContent();
        }).WithName("DeleteCurrentUser");

        return group;
    }
}
