namespace Conscia.Application.DTOs;

public class UpdateBudgetDto
{
    public decimal? MonthlyLimit { get; set; }
    public string? Category { get; set; }
}
