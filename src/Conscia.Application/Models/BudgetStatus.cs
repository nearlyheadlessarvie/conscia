using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Models;

public class BudgetStatus
{
    public Guid Id { get; init; }
    public Guid UserId { get; init; }
    public string Category { get; init; } = string.Empty;
    public decimal MonthlyLimit { get; init; }
    public decimal CurrentSpend { get; init; }
    public string CurrencyCode { get; init; } = "USD";
    public RecordScope Scope { get; init; } = RecordScope.Personal;
    public Guid? FamilySpaceId { get; init; }
    public DateTime? SharedAt { get; init; }
    public Guid? SharedByUserId { get; init; }

    public decimal PercentUsed => MonthlyLimit > 0 ? (CurrentSpend / MonthlyLimit) * 100 : 0;
    public bool IsOverBudget => CurrentSpend > MonthlyLimit;

    public static BudgetStatus FromBudget(Budget budget, decimal currentSpend) =>
        new()
        {
            Id = budget.Id,
            UserId = budget.UserId,
            Category = budget.Category,
            MonthlyLimit = budget.MonthlyLimit,
            CurrentSpend = currentSpend,
            CurrencyCode = budget.CurrencyCode,
            Scope = budget.Scope,
            FamilySpaceId = budget.FamilySpaceId,
            SharedAt = budget.SharedAt,
            SharedByUserId = budget.SharedByUserId
        };
}
