namespace Conscia.Domain.Entities;

public class AIInteraction
{
    public Guid Id { get; set; }
    public Guid TransactionId { get; set; }
    public Guid UserId { get; set; }
    public string DevilMsg { get; set; } = string.Empty;
    public string AngelMsg { get; set; } = string.Empty;
    public string NeutralMsg { get; set; } = string.Empty;
    public string? InteractionType { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
