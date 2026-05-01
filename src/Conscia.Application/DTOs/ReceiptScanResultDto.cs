namespace Conscia.Application.DTOs;

public class ReceiptScanResultDto
{
    public string? Merchant { get; set; }
    public decimal? Total { get; set; }
    public DateTime? Date { get; set; }
    public string? CurrencyCode { get; set; }
    public List<LineItemDto>? LineItems { get; set; }
    public double Confidence { get; set; }
}

public class LineItemDto
{
    public string Description { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public int Quantity { get; set; } = 1;
}
