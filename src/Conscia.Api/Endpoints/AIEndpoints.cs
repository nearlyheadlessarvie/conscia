using System.Diagnostics;
using System.Globalization;
using Conscia.Api.Extensions;
using Conscia.Api.Telemetry;
using Conscia.Application.Constants;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using FluentValidation;

namespace Conscia.Api.Endpoints;

public static class AIEndpoints
{
    public static RouteGroupBuilder MapAIEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/ai")
            .RequireAuthorization()
            .WithTags("AI");

        group.MapPost("/pre-purchase", async (
            HttpContext ctx,
            PrePurchaseRequestDto dto,
            IAIService aiService,
            IBudgetService budgetService,
            ITransactionService transactionService,
            IAIInteractionRepository aiRepo,
            ISubscriptionService subSvc,
            IUserService userService,
            IFamilySpaceRepository familySpaces,
            IBudgetRepository budgetRepository,
            ITransactionRepository transactionRepository,
            IRecurringScheduleRepository recurringRepository,
            IValidator<PrePurchaseRequestDto> validator) =>
        {
            using var activity = ConsciaActivitySources.AI.StartActivity("PrePurchaseAdvice");
            var sw = Stopwatch.StartNew();

            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            activity?.SetTag("ai.request.category", dto.Category);
            activity?.SetTag("ai.request.amount", dto.Amount);
            activity?.SetTag("ai.request.currency", dto.CurrencyCode);

            var userId = ctx.User.GetUserId();
            var user = await userService.GetByIdAsync(userId, ctx.RequestAborted);
            var contextScope = NormalizeContextScope(dto.ContextScope);
            string? familyContextSummary = null;

            if (contextScope == "family")
            {
                var membership = await familySpaces.GetMembershipByUserIdAsync(userId, ctx.RequestAborted);
                if (membership is null)
                    return Results.Json(
                        new { error = "Family advice requires a Family Space." },
                        statusCode: StatusCodes.Status403Forbidden);

                familyContextSummary = await BuildFamilyContextSummaryAsync(
                    membership.FamilySpaceId,
                    budgetRepository,
                    transactionRepository,
                    recurringRepository,
                    ctx.RequestAborted);
            }

            var isPremium = await subSvc.IsPremiumAsync(userId, ctx.RequestAborted);
            if (!isPremium)
            {
                var monthStart = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);
                var count = await aiRepo.CountByUserAsync(userId, monthStart, "PrePurchase", ctx.RequestAborted);
                if (count >= FreemiumLimits.FreeAiAssistsPerMonth)
                    return Results.Json(
                        new { error = $"Free tier limit: {FreemiumLimits.FreeAiAssistsPerMonth} AI assists per month", upgradeRequired = true },
                        statusCode: 403);
            }

            decimal? budgetPercent = null;
            var budgets = await budgetService.ListStatusesByUserAsync(userId, ct: ctx.RequestAborted);
            var matchedBudget = budgets.FirstOrDefault(b =>
                b.Category.Equals(dto.Category, StringComparison.OrdinalIgnoreCase));
            if (matchedBudget is not null)
                budgetPercent = matchedBudget.PercentUsed;

            var weekAgo = DateTime.UtcNow.AddDays(-7);
            var recentTxns = await transactionService.ListAsync(userId, 1, 100, null, ctx.RequestAborted);
            var recentRegrets = recentTxns.Items.Count(t => t.RegretLevel == RegretLevel.Regret);
            var spendingThisWeek = recentTxns.Items.Count(t => t.Date >= weekAgo);

            var context = new AIContext
            {
                UserId = userId,
                Amount = dto.Amount,
                CurrencyCode = dto.CurrencyCode,
                Category = dto.Category,
                BudgetPercentUsed = budgetPercent,
                RecentRegrets = recentRegrets,
                SpendingFrequencyThisWeek = spendingThisWeek,
                AiPersonalityIntensity = user?.AiPersonalityIntensity ?? "balanced",
                ContextScope = contextScope,
                FamilyContextSummary = familyContextSummary,
                InsightContext = dto.InsightContext
            };

            var response = await aiService.GeneratePrePurchaseResponseAsync(context, ctx.RequestAborted);

            activity?.SetTag("ai.response.has_budget_context", matchedBudget is not null);
            activity?.SetTag("ai.response.duration_ms", sw.ElapsedMilliseconds);

            await aiRepo.AddAsync(new AIInteraction
            {
                Id = Guid.NewGuid(),
                TransactionId = Guid.Empty,
                UserId = userId,
                DevilMsg = response.DevilMessage,
                AngelMsg = response.AngelMessage,
                NeutralMsg = response.NeutralMessage,
                InteractionType = "PrePurchase",
                CreatedAt = DateTime.UtcNow
            }, ctx.RequestAborted);

            return Results.Ok(new
            {
                response.DevilMessage,
                response.AngelMessage,
                response.NeutralMessage,
                Budget = matchedBudget is not null ? new
                {
                    matchedBudget.Category,
                    matchedBudget.MonthlyLimit,
                    matchedBudget.CurrentSpend,
                    matchedBudget.PercentUsed,
                    matchedBudget.IsOverBudget
                } : null
            });
        }).WithName("PrePurchaseAdvice");

        group.MapPost("/reflection", async (
            HttpContext ctx,
            ReflectionRequestDto dto,
            IAIService aiService,
            IBudgetService budgetService,
            ITransactionService transactionService,
            IAIInteractionRepository aiRepo,
            ISubscriptionService subSvc,
            IUserService userService) =>
        {
            using var activity = ConsciaActivitySources.AI.StartActivity("ReflectionAdvice");
            var sw = Stopwatch.StartNew();

            var userId = ctx.User.GetUserId();
            var user = await userService.GetByIdAsync(userId, ctx.RequestAborted);

            var isPremium = await subSvc.IsPremiumAsync(userId, ctx.RequestAborted);
            if (!isPremium)
            {
                var monthStart = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);
                var count = await aiRepo.CountByUserAsync(userId, monthStart, "Reflection", ctx.RequestAborted);
                if (count >= FreemiumLimits.FreeReflectionsPerMonth)
                    return Results.Json(
                        new { error = $"Free tier limit: {FreemiumLimits.FreeReflectionsPerMonth} reflections per month", upgradeRequired = true },
                        statusCode: 403);
            }

            var transaction = await transactionService.GetByIdAsync(userId, dto.TransactionId, ctx.RequestAborted);
            if (transaction is null)
                return Results.NotFound(new { error = "Transaction not found" });

            decimal? budgetPercent = null;
            var budgets = await budgetService.ListStatusesByUserAsync(userId, ct: ctx.RequestAborted);
            var matchedBudget = budgets.FirstOrDefault(b =>
                b.Category.Equals(transaction.Category, StringComparison.OrdinalIgnoreCase));
            if (matchedBudget is not null)
                budgetPercent = matchedBudget.PercentUsed;

            var recentTxns = await transactionService.ListAsync(userId, 1, 100, null, ctx.RequestAborted);
            var recentRegrets = recentTxns.Items.Count(t => t.RegretLevel == RegretLevel.Regret);

            var context = new AIContext
            {
                UserId = userId,
                Amount = transaction.Amount.Amount,
                CurrencyCode = transaction.Amount.CurrencyCode,
                Category = transaction.Category,
                BudgetPercentUsed = budgetPercent,
                RecentRegrets = recentRegrets,
                AiPersonalityIntensity = user?.AiPersonalityIntensity ?? "balanced"
            };

            var response = await aiService.GenerateReflectionAsync(context, ctx.RequestAborted);

            activity?.SetTag("ai.request.category", transaction.Category);
            activity?.SetTag("ai.request.amount", transaction.Amount.Amount);
            activity?.SetTag("ai.request.currency", transaction.Amount.CurrencyCode);
            activity?.SetTag("ai.response.has_budget_context", matchedBudget is not null);
            activity?.SetTag("ai.response.duration_ms", sw.ElapsedMilliseconds);

            await aiRepo.AddAsync(new AIInteraction
            {
                Id = Guid.NewGuid(),
                TransactionId = dto.TransactionId,
                UserId = userId,
                DevilMsg = response.DevilMessage,
                AngelMsg = response.AngelMessage,
                NeutralMsg = response.NeutralMessage,
                InteractionType = "Reflection",
                CreatedAt = DateTime.UtcNow
            }, ctx.RequestAborted);

            return Results.Ok(new
            {
                response.DevilMessage,
                response.AngelMessage,
                response.NeutralMessage
            });
        }).WithName("ReflectionAdvice");

        return group;
    }

    private static string NormalizeContextScope(string? contextScope) =>
        string.Equals(contextScope, "family", StringComparison.OrdinalIgnoreCase)
            ? "family"
            : "personal";

    private static async Task<string> BuildFamilyContextSummaryAsync(
        Guid familySpaceId,
        IBudgetRepository budgetRepository,
        ITransactionRepository transactionRepository,
        IRecurringScheduleRepository recurringRepository,
        CancellationToken ct)
    {
        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

        var budgets = await budgetRepository.ListByFamilySpaceAsync(familySpaceId, ct);
        var transactions = await transactionRepository.GetByFamilySpaceAndDateRangeAsync(familySpaceId, monthStart, monthEnd, ct);
        var recurring = await recurringRepository.ListByFamilySpaceAsync(familySpaceId, ct);

        var expenses = transactions
            .Where(t => t.Type == TransactionType.Expense)
            .GroupBy(t => t.Amount.CurrencyCode)
            .Select(g => FormatMoney(g.Sum(t => t.Amount.Amount), g.Key))
            .DefaultIfEmpty("none")
            .ToList();
        var contributions = transactions
            .Where(t => t.Type == TransactionType.Income)
            .GroupBy(t => t.Amount.CurrencyCode)
            .Select(g => FormatMoney(g.Sum(t => t.Amount.Amount), g.Key))
            .DefaultIfEmpty("none")
            .ToList();
        var activeRecurring = recurring.Where(r => r.IsActive).ToList();

        return string.Join('\n', new[]
        {
            "Family context:",
            $"- Shared budget categories: {FormatList(budgets.Select(b => b.Category).Distinct(StringComparer.OrdinalIgnoreCase))}",
            $"- Current month family expenses total: {string.Join(", ", expenses)}",
            $"- Current month family contributions total: {string.Join(", ", contributions)}",
            $"- Active family recurring obligations: {activeRecurring.Count}",
            $"- Active family recurring categories: {FormatList(activeRecurring.Select(r => r.Category).Distinct(StringComparer.OrdinalIgnoreCase))}"
        });
    }

    private static string FormatList(IEnumerable<string> values)
    {
        var list = values.Where(v => !string.IsNullOrWhiteSpace(v)).Take(8).ToList();
        return list.Count == 0 ? "none" : string.Join(", ", list);
    }

    private static string FormatMoney(decimal amount, string currencyCode) =>
        $"{currencyCode.ToUpperInvariant()} {amount.ToString("F2", CultureInfo.InvariantCulture)}";
}
