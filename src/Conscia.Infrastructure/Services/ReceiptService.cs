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

    public Task<object?> GetByIdAsync(Guid userId, Guid receiptId, CancellationToken ct = default)
    {
        // MVP stub — real implementation fetches from storage
        return Task.FromResult<object?>(new
        {
            id = receiptId,
            status = "PendingReview",
            ocrConfidence = 0.85,
            needsReview = true,
            extractedData = new
            {
                merchant = "Sample Merchant",
                total = 29.99m,
                currencyCode = "USD",
                category = "Food",
                date = DateTime.UtcNow,
                items = new[]
                {
                    new { name = "Item 1", amount = 15.00m },
                    new { name = "Item 2", amount = 14.99m }
                }
            }
        });
    }

    public Task<object> ConfirmAsync(Guid userId, Guid receiptId, ConfirmReceiptRequest request, CancellationToken ct = default)
    {
        // MVP stub — real implementation creates a transaction from receipt data
        return Task.FromResult<object>(new
        {
            message = "Receipt confirmed",
            transactionId = Guid.NewGuid(),
            merchant = request.Merchant,
            amount = request.Amount,
            currencyCode = request.CurrencyCode,
            category = request.Category,
            date = request.Date
        });
    }
}
