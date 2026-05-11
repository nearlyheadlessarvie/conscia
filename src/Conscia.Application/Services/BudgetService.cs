using Conscia.Application.Interfaces;
using Conscia.Application.DTOs;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Conscia.Application.Services;

public class BudgetService : IBudgetService
{
    private readonly IBudgetRepository _repo;
    private readonly ITransactionRepository _transactionRepo;
    private readonly ILogger<BudgetService> _logger;
    private readonly IFamilySpaceRepository _familySpaces;

    public BudgetService(
        IBudgetRepository repo,
        ITransactionRepository transactionRepo,
        ILogger<BudgetService> logger,
        IFamilySpaceRepository familySpaces)
    {
        _repo = repo;
        _transactionRepo = transactionRepo;
        _logger = logger;
        _familySpaces = familySpaces;
    }

    public Task<Budget> CreateAsync(Guid userId, string category, decimal monthlyLimit, string currencyCode, CancellationToken ct = default) =>
        CreateAsync(userId, new CreateBudgetDto
        {
            Category = category,
            MonthlyLimit = monthlyLimit,
            CurrencyCode = currencyCode
        }, ct);

    public async Task<Budget> CreateAsync(Guid userId, CreateBudgetDto dto, CancellationToken ct = default)
    {
        var budget = new Budget
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Category = dto.Category,
            MonthlyLimit = dto.MonthlyLimit,
            CurrencyCode = dto.CurrencyCode
        };
        await EnsureCanWriteFamilyRecordAsync(userId, dto.Scope, dto.FamilySpaceId, ct);
        ApplyScope(budget, userId, dto.Scope, dto.FamilySpaceId);

        var result = await _repo.AddAsync(budget, ct);
        _logger.LogInformation("Creating budget {BudgetId} for user {UserId}, category {Category}",
            budget.Id, userId, dto.Category);
        return result;
    }

    public async Task<Budget?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var budget = await _repo.GetByIdAsync(id, ct);
        if (budget is null || budget.UserId != userId) return null;
        return budget;
    }

    public Task<IReadOnlyList<Budget>> ListByUserAsync(Guid userId, CancellationToken ct = default) =>
        _repo.ListByUserAsync(userId, ct);

    public async Task<BudgetStatus?> GetStatusByIdAsync(
        Guid userId,
        Guid id,
        DateTime? now = null,
        CancellationToken ct = default)
    {
        var budget = await GetByIdAsync(userId, id, ct);
        if (budget is null)
        {
            return null;
        }

        var spendsByCategory = await GetMonthlyExpenseTotalsByCategoryAsync(userId, now, ct);
        return BudgetStatus.FromBudget(
            budget,
            spendsByCategory.GetValueOrDefault(budget.Category, 0m));
    }

    public async Task<IReadOnlyList<BudgetStatus>> ListStatusesByUserAsync(
        Guid userId,
        DateTime? now = null,
        CancellationToken ct = default)
    {
        var budgets = await _repo.ListByUserAsync(userId, ct);
        var spendsByCategory = await GetMonthlyExpenseTotalsByCategoryAsync(userId, now, ct);

        return budgets
            .Select(budget => BudgetStatus.FromBudget(
                budget,
                spendsByCategory.GetValueOrDefault(budget.Category, 0m)))
            .ToList();
    }

    public async Task<Budget> UpdateAsync(Guid userId, Guid id, decimal? monthlyLimit, string? category, CancellationToken ct = default)
    {
        var budget = await _repo.GetByIdAsync(id, ct)
            ?? throw new KeyNotFoundException($"Budget {id} not found");

        if (budget.UserId != userId)
            throw new UnauthorizedAccessException("Budget does not belong to this user");

        if (monthlyLimit.HasValue)
            budget.MonthlyLimit = monthlyLimit.Value;
        if (category is not null)
            budget.Category = category;

        var updated = await _repo.UpdateAsync(budget, ct);

        return updated;
    }

    public async Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default)
    {
        var budget = await _repo.GetByIdAsync(id, ct)
            ?? throw new KeyNotFoundException($"Budget {id} not found");

        if (budget.UserId != userId)
            throw new UnauthorizedAccessException("Budget does not belong to this user");

        await _repo.DeleteAsync(id, ct);
    }

    private static void ApplyScope(Budget budget, Guid userId, RecordScope scope, Guid? familySpaceId)
    {
        budget.Scope = scope;
        if (scope == RecordScope.Family)
        {
            budget.FamilySpaceId = familySpaceId
                ?? throw new InvalidOperationException("Family Space is required for family budgets.");
            budget.SharedByUserId = userId;
            budget.SharedAt ??= DateTime.UtcNow;
            return;
        }

        budget.FamilySpaceId = null;
        budget.SharedByUserId = null;
        budget.SharedAt = null;
    }

    private async Task EnsureCanWriteFamilyRecordAsync(
        Guid userId,
        RecordScope scope,
        Guid? familySpaceId,
        CancellationToken ct)
    {
        if (scope != RecordScope.Family)
            return;

        if (!familySpaceId.HasValue)
            throw new InvalidOperationException("Family Space is required for family budgets.");

        var member = await _familySpaces.GetMembershipByUserIdAsync(userId, ct)
            ?? throw new UnauthorizedAccessException("You do not belong to a Family Space.");

        if (member.FamilySpaceId != familySpaceId.Value)
            throw new UnauthorizedAccessException("You do not belong to that Family Space.");

        if (member.Role == FamilyMemberRole.Viewer)
            throw new UnauthorizedAccessException("Viewer cannot create Family Space records.");
    }

    private async Task<Dictionary<string, decimal>> GetMonthlyExpenseTotalsByCategoryAsync(
        Guid userId,
        DateTime? now,
        CancellationToken ct)
    {
        var effectiveNow = (now ?? DateTime.UtcNow).ToUniversalTime();
        var monthStart = new DateTime(effectiveNow.Year, effectiveNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var monthEnd = monthStart.AddMonths(1).AddTicks(-1);

        var transactions = await _transactionRepo.GetByUserIdAndDateRangeAsync(userId, monthStart, monthEnd, ct);

        return transactions
            .Where(transaction =>
                transaction.Type == TransactionType.Expense &&
                transaction.Date >= monthStart &&
                transaction.Date <= monthEnd)
            .GroupBy(transaction => transaction.Category, StringComparer.OrdinalIgnoreCase)
            .ToDictionary(
                group => group.Key,
                group => group.Sum(transaction => transaction.Amount.Amount),
                StringComparer.OrdinalIgnoreCase);
    }
}
