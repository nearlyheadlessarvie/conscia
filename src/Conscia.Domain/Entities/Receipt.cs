using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class Receipt
{
    public Guid Id { get; set; }
    public Guid TransactionId { get; set; }
    public string S3Key { get; set; } = string.Empty;
    public string? ExtractedData { get; set; }
    public double OcrConfidence { get; set; }
    public bool NeedsReview { get; set; }
    public ReceiptStatus Status { get; set; } = ReceiptStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
