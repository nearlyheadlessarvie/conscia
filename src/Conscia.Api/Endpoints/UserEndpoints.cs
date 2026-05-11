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
                    user.LocationSuggestionsEnabled,
                    user.AiPersonalityIntensity,
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
                user.LocationSuggestionsEnabled,
                user.AiPersonalityIntensity,
            });
        }).WithName("UpdateCurrentUser");

        group.MapGet("/me/export", async (
            HttpContext ctx,
            IUserService svc,
            ITransactionService txnSvc,
            IBudgetService budgetSvc,
            IRecurringScheduleService recurringScheduleSvc,
            IAlertService alertSvc,
            IWeeklyInsightsRepository weeklyInsightsRepo,
            IPurchasePatternRepository purchasePatternRepo,
            IMonthlyCategorySpendRepository monthlyCategorySpendRepo,
            IAIInteractionRepository aiInteractionRepo,
            IConscienceJourneyRepository conscienceJourneyRepo,
            IPushDeviceTokenRepository pushDeviceTokenRepo) =>
        {
            var userId = ctx.User.GetUserId();
            var ct = ctx.RequestAborted;

            var user = await svc.GetByIdAsync(userId, ct);
            if (user is null) return Results.NotFound();

            var transactions = await txnSvc.ListAsync(userId, 1, 10000, null, ct);
            var budgets = await budgetSvc.ListStatusesByUserAsync(userId, ct: ct);
            var recurringSchedules = await recurringScheduleSvc.ListAsync(userId, ct);
            var alerts = await alertSvc.ListAlertsAsync(userId, ct);
            var weeklyInsights = await weeklyInsightsRepo.GetByUserIdAsync(userId, 1000, ct);
            var purchasePatternSummary = await purchasePatternRepo.GetSummaryAsync(userId, ct);
            var purchasePatternCategories = await purchasePatternRepo.GetCategoriesAsync(userId, ct);
            var purchasePatternMerchants = await purchasePatternRepo.GetMerchantsAsync(userId, ct);
            var monthlyCategorySpends = await monthlyCategorySpendRepo.ListByUserAsync(userId, ct);
            var aiInteractions = await aiInteractionRepo.ListByUserAsync(userId, null, null, 1000, ct);
            var journeyProgress = await conscienceJourneyRepo.GetProgressAsync(userId, ct);
            var journeyBadges = await conscienceJourneyRepo.GetBadgeProgressAsync(userId, ct);
            var journeyQuests = await conscienceJourneyRepo.ListQuestProgressAsync(userId, 1000, ct);
            var journeyEvents = await conscienceJourneyRepo.ListEventsAsync(userId, 1000, ct);
            var journeyMoments = await conscienceJourneyRepo.ListMascotMomentsAsync(userId, 100, ct);
            var pushDevices = await pushDeviceTokenRepo.GetActiveByUserAsync(userId, ct);

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
                    user.SpendingPersonality,
                    user.IncomeRange,
                    user.OccupationType,
                    user.HouseholdSize,
                    user.HasCompletedOnboarding,
                    user.LocationSuggestionsEnabled,
                    user.AiPersonalityIntensity
                },
                Transactions = transactions.Items,
                Budgets = budgets,
                RecurringSchedules = recurringSchedules,
                Alerts = alerts,
                Insights = new
                {
                    Weekly = weeklyInsights,
                    PurchasePatterns = new
                    {
                        Summary = purchasePatternSummary,
                        Categories = purchasePatternCategories,
                        Merchants = purchasePatternMerchants
                    },
                    MonthlyCategorySpends = monthlyCategorySpends
                },
                AIInteractions = aiInteractions,
                ConscienceJourney = new
                {
                    Progress = journeyProgress,
                    Badges = journeyBadges,
                    Quests = journeyQuests,
                    Events = journeyEvents,
                    MascotMoments = journeyMoments
                },
                PushNotificationDevices = pushDevices.Select(device => new
                {
                    device.Platform,
                    device.CreatedAt,
                    device.UpdatedAt,
                    device.LastSeenAt,
                    device.IsActive
                })
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
