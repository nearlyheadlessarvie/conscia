namespace ConstantsGen.Writers;

public static class DartWriter
{
    public static string Generate(
        Dictionary<string, int> freemiumLimits,
        string[] regretLevels,
        string[] subscriptionTiers,
        IReadOnlyList<string> expenseCategories,
        IReadOnlyList<string> incomeCategories,
        List<(string Code, string Name, string Symbol, string Flag)> currencies)
    {
        var sb = new System.Text.StringBuilder();

        sb.AppendLine("// GENERATED — do not edit by hand.");
        sb.AppendLine("// Regenerate: dotnet run --project tools/ConstantsGen");
        sb.AppendLine("// Source: Conscia.Domain + tools/ConstantsGen/Metadata/CurrencyMetadata.cs");
        sb.AppendLine();

        // FreemiumLimits
        sb.AppendLine("// ── Freemium limits ──────────────────────────────────────────────");
        sb.AppendLine("class FreemiumLimits {");
        sb.AppendLine("  FreemiumLimits._();");
        foreach (var (key, value) in freemiumLimits)
            sb.AppendLine($"  static const int {key} = {value};");
        sb.AppendLine("}");
        sb.AppendLine();

        // Enums
        sb.AppendLine("// ── Enums ────────────────────────────────────────────────────────");
        sb.AppendLine($"enum RegretLevel {{ {string.Join(", ", regretLevels.Select(ToCamelCase))} }}");
        sb.AppendLine($"enum SubscriptionTier {{ {string.Join(", ", subscriptionTiers.Select(ToCamelCase))} }}");
        sb.AppendLine();

        // Categories
        sb.AppendLine("// ── Categories ───────────────────────────────────────────────────");
        sb.AppendLine("const List<String> expenseCategories = [");
        foreach (var cat in expenseCategories)
            sb.AppendLine($"  '{EscapeDart(cat)}',");
        sb.AppendLine("];");
        sb.AppendLine();
        sb.AppendLine("const List<String> incomeCategories = [");
        foreach (var cat in incomeCategories)
            sb.AppendLine($"  '{EscapeDart(cat)}',");
        sb.AppendLine("];");
        sb.AppendLine();

        // CurrencyInfo class
        sb.AppendLine("// ── Currencies ───────────────────────────────────────────────────");
        sb.AppendLine("class CurrencyInfo {");
        sb.AppendLine("  final String code;");
        sb.AppendLine("  final String name;");
        sb.AppendLine("  final String symbol;");
        sb.AppendLine("  final String flag;");
        sb.AppendLine("  const CurrencyInfo(this.code, this.name, this.symbol, this.flag);");
        sb.AppendLine("}");
        sb.AppendLine();

        // Currency list
        sb.AppendLine("const List<CurrencyInfo> supportedCurrencies = [");
        foreach (var (code, name, symbol, flag) in currencies)
            sb.AppendLine($"  CurrencyInfo('{code}', '{EscapeDart(name)}', '{EscapeDart(symbol)}', '{flag}'),");
        sb.AppendLine("];");

        return sb.ToString();
    }

    private static string ToCamelCase(string s) =>
        string.IsNullOrEmpty(s) ? s : char.ToLower(s[0]) + s[1..];

    private static string EscapeDart(string s) =>
        s.Replace("'", "\\'").Replace("\\", "\\\\").Replace("$", "\\$");
}
