using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class EmailSuppression
{
    public string Email { get; set; } = string.Empty;
    public EmailSuppressionReason Reason { get; set; }
    public string Source { get; set; } = "SES";
    public DateTime SuppressedAt { get; set; } = DateTime.UtcNow;
    public string? SourceEventId { get; set; }
    public string? ProviderMessageId { get; set; }
}
