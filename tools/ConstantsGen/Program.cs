using Conscia.Application.Constants;
using Conscia.Domain.Constants;
using Conscia.Domain.Enums;
using ConstantsGen.Metadata;
using ConstantsGen.Writers;

var repoRoot = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../"));
var outputPath = Path.Combine(repoRoot, "app/lib/core/constants/generated/app_constants.g.dart");

var freemiumLimits = new Dictionary<string, int>
{
    ["freeBudgetCategories"] = FreemiumLimits.FreeBudgetCategories,
    ["freeAiAssistsPerMonth"] = FreemiumLimits.FreeAiAssistsPerMonth,
    ["freeReflectionsPerMonth"] = FreemiumLimits.FreeReflectionsPerMonth,
    ["freeCurrencies"] = FreemiumLimits.FreeCurrencies,
};

var regretLevels = Enum.GetNames<RegretLevel>();
var subscriptionTiers = Enum.GetNames<SubscriptionTier>();

var currencies = SupportedCurrencies.Codes
    .Select(code =>
    {
        if (!CurrencyMetadata.Map.TryGetValue(code, out var meta))
            throw new InvalidOperationException($"Missing metadata for currency code: {code}. Add it to CurrencyMetadata.Map.");
        return (code, meta.Name, meta.Symbol, meta.Flag);
    })
    .ToList();

var dart = DartWriter.Generate(
    freemiumLimits,
    regretLevels,
    subscriptionTiers,
    TransactionCategories.Expense,
    TransactionCategories.Income,
    currencies);

Directory.CreateDirectory(Path.GetDirectoryName(outputPath)!);
await File.WriteAllTextAsync(outputPath, dart);

Console.WriteLine($"✅ app_constants.g.dart written ({currencies.Count} currencies, " +
    $"{TransactionCategories.Expense.Count} expense categories, " +
    $"{TransactionCategories.Income.Count} income categories)");
