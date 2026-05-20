namespace Conscia.Application.Configuration;

public sealed class InviteEmailOptions
{
    public const string SectionName = "InviteEmail";

    public string? FromEmail { get; set; }
    public string? ConfigurationSetName { get; set; }
    public string DeepLinkBaseUri { get; set; } = "https://getconscia.com/open/family-invite";

    public bool IsConfigured => !string.IsNullOrWhiteSpace(FromEmail);

    public string BuildInviteLink(Guid inviteId)
    {
        var separator = DeepLinkBaseUri.Contains('?', StringComparison.Ordinal) ? "&" : "?";
        return $"{DeepLinkBaseUri}{separator}inviteId={Uri.EscapeDataString(inviteId.ToString())}";
    }
}
