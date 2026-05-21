namespace Conscia.Application.Configuration;

public sealed class AdminBootstrapOptions
{
    public const string SectionName = "AdminBootstrap";

    public List<string> Emails { get; set; } = [];
}
