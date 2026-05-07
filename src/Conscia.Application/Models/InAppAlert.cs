namespace Conscia.Application.Models;

public class InAppAlert
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string AlertKey { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public string TriggerName { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public int Priority { get; set; }
    public string? ActionLabel { get; set; }
    public string? ActionRoute { get; set; }
    public string? Category { get; set; }
    public string? Counterparty { get; set; }
    public Guid? TransactionId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public long TTL { get; set; }
}
