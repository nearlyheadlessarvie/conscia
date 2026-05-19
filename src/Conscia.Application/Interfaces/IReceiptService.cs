namespace Conscia.Application.Interfaces;

public interface IReceiptService
{
    Task<ReceiptScanResult> ScanAsync(
        Guid userId,
        Stream imageStream,
        string contentType = "image/jpeg",
        CancellationToken ct = default);

    Task<object?> GetByIdAsync(Guid userId, Guid receiptId, CancellationToken ct = default);
    Task<Domain.Entities.Transaction> ConfirmAsync(Guid userId, Guid receiptId, ConfirmReceiptRequest request, CancellationToken ct = default);
}

public sealed record ConfirmReceiptRequest(string Merchant, decimal Amount, string CurrencyCode, string Category, DateTime Date);
