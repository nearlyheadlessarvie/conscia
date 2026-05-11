using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public class CreateBudgetDto
{
    public string Category { get; set; } = string.Empty;
    public decimal MonthlyLimit { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public RecordScope Scope { get; set; } = RecordScope.Personal;
    public Guid? FamilySpaceId { get; set; }
}
