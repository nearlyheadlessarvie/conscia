using Conscia.Domain.Enums;

namespace Conscia.Domain.Entities;

public class UserIdentity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public AuthProvider Provider { get; set; }
    public string ProviderSub { get; set; } = string.Empty;
    public UserIdentityRole Role { get; set; } = UserIdentityRole.Member;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
