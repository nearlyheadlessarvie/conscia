using System.Text.RegularExpressions;

namespace Conscia.AI.Prompts;

public static partial class PromptSanitizer
{
    private const int MaxFieldLength = 200;

    public static string Sanitize(string? input, int maxLength = MaxFieldLength)
    {
        if (string.IsNullOrWhiteSpace(input))
            return string.Empty;

        var cleaned = ControlCharRegex().Replace(input, "");

        cleaned = PromptBreakRegex().Replace(cleaned, "");

        if (cleaned.Length > maxLength)
            cleaned = cleaned[..maxLength];

        return cleaned.Trim();
    }

    [GeneratedRegex(@"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]")]
    private static partial Regex ControlCharRegex();

    [GeneratedRegex(@"(```|<\|im_end\|>|<\|im_start\|>|<<SYS>>|<</SYS>>|\[INST\]|\[/INST\])", RegexOptions.IgnoreCase)]
    private static partial Regex PromptBreakRegex();
}
