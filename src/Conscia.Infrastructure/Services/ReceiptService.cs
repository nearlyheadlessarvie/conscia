using Conscia.Application.Interfaces;

namespace Conscia.Infrastructure.Services;

public class ReceiptService : IReceiptService
{
    public Task<ReceiptScanResult> ScanAsync(Guid userId, Stream imageStream, CancellationToken ct = default)
    {
        // MVP stub — real implementation uploads to S3 + calls Textract
        return Task.FromResult(new ReceiptScanResult(
            Id: Guid.NewGuid(),
            Merchant: "Scanned Receipt",
            Total: 0m,
            CurrencyCode: "USD",
            Date: DateTime.UtcNow,
            Confidence: 0.0,
            LineItems: new List<ReceiptLineItem>()));
    }

    public Task<object> ConfirmAsync(Guid userId, Guid receiptId, CancellationToken ct = default)
    {
        // MVP stub — real implementation creates a transaction from receipt data
        return Task.FromResult<object>(new { message = "Receipt confirmed", transactionId = Guid.NewGuid() });
    }
}
