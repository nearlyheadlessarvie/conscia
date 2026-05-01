using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public class UpdateTransactionDto
{
    public TransactionType? Type { get; set; }
    public decimal? Amount { get; set; }
    public string? CurrencyCode { get; set; }
    public string? Category { get; set; }
    public string? Merchant { get; set; }
    public DateTime? Date { get; set; }
}
