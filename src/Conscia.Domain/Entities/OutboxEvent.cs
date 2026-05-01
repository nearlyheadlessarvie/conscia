using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class OutboxEvent
{
    public Guid Id { get; set; }
    public Guid AggregateId { get; set; }
    public OutboxEventType EventType { get; set; }
    public string Payload { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}
