using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class FamilyMember
{
    public Guid Id { get; set; }
    public Guid FamilySpaceId { get; set; }
    public Guid UserId { get; set; }
    public FamilyMemberRole Role { get; set; }
    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;
}
