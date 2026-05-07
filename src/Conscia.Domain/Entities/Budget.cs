namespace Conscia.Domain.Entities;

public class Budget
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Category { get; set; } = string.Empty;
    public decimal MonthlyLimit { get; set; }
    public string CurrencyCode { get; set; } = "USD";
}
