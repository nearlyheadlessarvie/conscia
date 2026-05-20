using System.Text;
using System.Text.Json;

namespace Conscia.Application.Configuration;

public sealed class FirebaseAdminOptions
{
    public const string SectionName = "Firebase";

    public string? AdminServiceAccountJson { get; set; }
    public string? ProjectId { get; set; }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(ResolvedServiceAccountJson) &&
                                !string.IsNullOrWhiteSpace(ResolvedProjectId);

    public string? ResolvedServiceAccountJson => DecodeIfBase64(AdminServiceAccountJson);

    public string? ResolvedProjectId =>
        !string.IsNullOrWhiteSpace(ProjectId)
            ? ProjectId
            : TryReadProjectId(ResolvedServiceAccountJson);

    private static string? DecodeIfBase64(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        if (trimmed.StartsWith("{", StringComparison.Ordinal))
        {
            return trimmed;
        }

        try
        {
            var decoded = Encoding.UTF8.GetString(Convert.FromBase64String(trimmed));
            return decoded.TrimStart().StartsWith("{", StringComparison.Ordinal)
                ? decoded
                : trimmed;
        }
        catch
        {
            return trimmed;
        }
    }

    private static string? TryReadProjectId(string? json)
    {
        if (string.IsNullOrWhiteSpace(json))
        {
            return null;
        }

        try
        {
            using var document = JsonDocument.Parse(json);
            return document.RootElement.TryGetProperty("project_id", out var projectIdElement)
                ? projectIdElement.GetString()
                : null;
        }
        catch
        {
            return null;
        }
    }
}
