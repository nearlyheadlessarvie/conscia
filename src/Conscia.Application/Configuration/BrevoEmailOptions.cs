namespace Conscia.Application.Configuration;

public sealed class BrevoEmailOptions
{
    public const string SectionName = "Brevo";

    public string? ApiKey { get; set; }
    public string? SenderEmail { get; set; }
    public string SenderName { get; set; } = "Conscia";

    public bool IsConfigured =>
        !string.IsNullOrWhiteSpace(ApiKey) &&
        !string.IsNullOrWhiteSpace(SenderEmail);
}
