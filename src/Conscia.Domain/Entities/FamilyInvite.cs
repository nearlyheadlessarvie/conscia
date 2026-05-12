using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class FamilyInvite
{
    public Guid Id { get; set; }
    public Guid FamilySpaceId { get; set; }
    public string Email { get; set; } = string.Empty;
    public FamilyMemberRole Role { get; set; }
    public Guid InvitedByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public DateTime? AcceptedAt { get; set; }
    public DateTime? DeclinedAt { get; set; }
}
