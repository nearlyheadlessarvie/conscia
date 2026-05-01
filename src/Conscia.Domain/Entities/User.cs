namespace Conscia.Domain.Entities;

public class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string CognitoSub { get; set; } = string.Empty;
    public string PreferredCurrency { get; set; } = "USD";
    public string Locale { get; set; } = "en-US";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
