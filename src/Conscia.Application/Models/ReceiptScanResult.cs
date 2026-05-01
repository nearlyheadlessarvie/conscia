namespace Conscia.Application.Interfaces;

public sealed record ReceiptScanResult(
    Guid Id,
    string? Merchant,
    decimal Total,
    string CurrencyCode,
    DateTime? Date,
    double Confidence,
    List<ReceiptLineItem> LineItems);

public sealed record ReceiptLineItem(string Description, decimal Amount);
