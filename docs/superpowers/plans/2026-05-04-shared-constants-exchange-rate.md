# Shared Constants Generator & Exchange Rate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish .NET as the single source of truth for domain constants (freemium limits, enums, categories, currencies) via a code-generation tool that writes a Dart file, and wire up live exchange rate auto-fetching with client override support.

**Architecture:** A .NET console tool (`tools/ConstantsGen`) references `Conscia.Domain` directly and writes `app/lib/core/constants/generated/app_constants.g.dart`. A new `IExchangeRateService` in `Conscia.Infrastructure` calls open.er-api.com with a 24-hour in-memory cache; `TransactionService` calls it when a transaction currency differs from the user's base currency and no override was provided. Flutter shows a live-rate placeholder in the exchange rate field and sends an optional override.

**Tech Stack:** .NET 9 console app, `IMemoryCache`, `HttpClient` (open.er-api.com), Flutter Riverpod `FutureProvider.family`, Freezed, build_runner, GitHub Actions.

---

## File Map

**Create (backend):**
- `src/Conscia.Domain/Constants/SupportedCurrencies.cs`
- `src/Conscia.Domain/Constants/TransactionCategories.cs`
- `src/Conscia.Application/Interfaces/IExchangeRateService.cs`
- `src/Conscia.Infrastructure/Services/ExchangeRateService.cs`
- `src/Conscia.Api/Endpoints/ExchangeRateEndpoints.cs`

**Modify (backend):**
- `src/Conscia.Application/DTOs/CreateTransactionDto.cs` — rename field, add `BaseCurrencyCode`
- `src/Conscia.Application/Services/TransactionService.cs` — inject `IExchangeRateService`, auto-fetch rate
- `src/Conscia.Api/Program.cs` — register `IMemoryCache`, `IExchangeRateService`, map exchange rate endpoints

**Create (generator tool):**
- `tools/ConstantsGen/ConstantsGen.csproj`
- `tools/ConstantsGen/Program.cs`
- `tools/ConstantsGen/Writers/DartWriter.cs`
- `tools/ConstantsGen/Metadata/CurrencyMetadata.cs`

**Create (generated — do not hand-edit):**
- `app/lib/core/constants/generated/app_constants.g.dart`

**Delete (Flutter):**
- `app/lib/core/constants/tier_limits.dart`
- `app/lib/core/constants/currencies.dart`

**Modify (Flutter):**
- `app/lib/providers/user_provider.dart` — swap import; move `fromCountry` logic inline
- `app/lib/screens/transactions/widgets/category_picker.dart` — import generated lists
- `app/lib/core/constants/category_icons.dart` — import generated lists
- `app/lib/models/transaction.dart` — add `exchangeRateToBase: double?`
- `app/lib/services/transaction_service.dart` — add `baseCurrencyCode`, `exchangeRateOverride` to DTO
- `app/lib/screens/transactions/transaction_form_screen.dart` — exchange rate field
- Any file importing `tier_limits.dart` or `currencies.dart`

**Create (Flutter):**
- `app/lib/providers/exchange_rate_provider.dart`

**Create (CI):**
- `.github/workflows/constants-drift.yml`

**Create (tests):**
- `tests/Conscia.Tests.Unit/Domain/SupportedCurrenciesTests.cs`
- `tests/Conscia.Tests.Unit/Domain/TransactionCategoriesTests.cs`
- `tests/Conscia.Tests.Unit/Application/ExchangeRateServiceTests.cs`
- `tests/Conscia.Tests.Unit/Api/ExchangeRateEndpointTests.cs`

---

### Task 1: Domain Constants — SupportedCurrencies & TransactionCategories

**Files:**
- Create: `src/Conscia.Domain/Constants/SupportedCurrencies.cs`
- Create: `src/Conscia.Domain/Constants/TransactionCategories.cs`
- Create: `tests/Conscia.Tests.Unit/Domain/SupportedCurrenciesTests.cs`
- Create: `tests/Conscia.Tests.Unit/Domain/TransactionCategoriesTests.cs`

- [ ] **Step 1: Write failing tests**

```csharp
// tests/Conscia.Tests.Unit/Domain/SupportedCurrenciesTests.cs
using Conscia.Domain.Constants;

namespace Conscia.Tests.Unit.Domain;

public class SupportedCurrenciesTests
{
    [Fact]
    public void Codes_IsNotEmpty() =>
        Assert.NotEmpty(SupportedCurrencies.Codes);

    [Fact]
    public void Codes_AllAreThreeCharacters() =>
        Assert.All(SupportedCurrencies.Codes, c => Assert.Equal(3, c.Length));

    [Fact]
    public void Codes_AllAreUpperCase() =>
        Assert.All(SupportedCurrencies.Codes, c => Assert.Equal(c, c.ToUpperInvariant()));

    [Fact]
    public void Codes_ContainsCommonCurrencies()
    {
        Assert.Contains("USD", SupportedCurrencies.Codes);
        Assert.Contains("EUR", SupportedCurrencies.Codes);
        Assert.Contains("GBP", SupportedCurrencies.Codes);
        Assert.Contains("JPY", SupportedCurrencies.Codes);
    }

    [Fact]
    public void Codes_NoDuplicates() =>
        Assert.Equal(SupportedCurrencies.Codes.Count, SupportedCurrencies.Codes.Distinct().Count());
}
```

```csharp
// tests/Conscia.Tests.Unit/Domain/TransactionCategoriesTests.cs
using Conscia.Domain.Constants;

namespace Conscia.Tests.Unit.Domain;

public class TransactionCategoriesTests
{
    [Fact]
    public void Expense_IsNotEmpty() => Assert.NotEmpty(TransactionCategories.Expense);

    [Fact]
    public void Income_IsNotEmpty() => Assert.NotEmpty(TransactionCategories.Income);

    [Fact]
    public void Expense_ContainsExpectedCategories()
    {
        Assert.Contains("Groceries", TransactionCategories.Expense);
        Assert.Contains("Dining", TransactionCategories.Expense);
        Assert.Contains("Transport", TransactionCategories.Expense);
    }

    [Fact]
    public void Income_ContainsExpectedCategories()
    {
        Assert.Contains("Salary", TransactionCategories.Income);
        Assert.Contains("Freelance", TransactionCategories.Income);
    }

    [Fact]
    public void Expense_DoesNotContainIncomeSalary() =>
        Assert.DoesNotContain("Salary", TransactionCategories.Expense);
}
```

- [ ] **Step 2: Run tests — expect compile failure**

```bash
cd c:/Users/nearl/Repos/conscia
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~SupportedCurrencies|FullyQualifiedName~TransactionCategories" 2>&1 | tail -5
```

Expected: build error — `SupportedCurrencies` and `TransactionCategories` not defined.

- [ ] **Step 3: Create `SupportedCurrencies.cs`**

```csharp
// src/Conscia.Domain/Constants/SupportedCurrencies.cs
namespace Conscia.Domain.Constants;

public static class SupportedCurrencies
{
    public static readonly IReadOnlyList<string> Codes = new[]
    {
        "AED", "AFN", "ALL", "AMD", "ARS", "AUD", "AWG", "AZN",
        "BAM", "BBD", "BDT", "BGN", "BHD", "BND", "BOB", "BRL",
        "BWP", "BYN", "CAD", "CHF", "CLP", "CNY", "COP", "CRC",
        "CUP", "CZK", "DKK", "DOP", "DZD", "EGP", "ETB", "EUR",
        "FJD", "GBP", "GEL", "GHS", "GTQ", "GYD", "HKD", "HNL",
        "HTG", "HUF", "IDR", "ILS", "INR", "IQD", "IRR", "ISK",
        "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KWD", "KZT",
        "LAK", "LBP", "LKR", "MAD", "MDL", "MGA", "MKD", "MMK",
        "MNT", "MUR", "MVR", "MXN", "MYR", "MZN", "NAD", "NGN",
        "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PHP",
        "PKR", "PLN", "PYG", "QAR", "RON", "RSD", "SAR", "SEK",
        "SGD", "SRD", "THB", "TJS", "TND", "TRY", "TTD", "TWD",
        "TZS", "UAH", "UGX", "USD", "UYU", "UZS", "VND", "WST",
        "XAF", "XOF", "YER", "ZAR", "ZMW"
    };
}
```

- [ ] **Step 4: Create `TransactionCategories.cs`**

```csharp
// src/Conscia.Domain/Constants/TransactionCategories.cs
namespace Conscia.Domain.Constants;

public static class TransactionCategories
{
    public static readonly IReadOnlyList<string> Expense = new[]
    {
        "Groceries", "Dining", "Transport", "Entertainment",
        "Gaming", "Shopping", "Health", "Bills",
        "Education", "Travel", "Coffee", "Subscriptions", "Gift", "Other"
    };

    public static readonly IReadOnlyList<string> Income = new[]
    {
        "Salary", "Freelance", "Business", "Investment",
        "Rental Income", "Bonus", "Gift", "Other"
    };
}
```

- [ ] **Step 5: Run tests — expect pass**

```bash
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~SupportedCurrencies|FullyQualifiedName~TransactionCategories" 2>&1 | tail -5
```

Expected: `Passed! - Failed: 0, Passed: 10`

- [ ] **Step 6: Commit**

```bash
git add src/Conscia.Domain/Constants/ tests/Conscia.Tests.Unit/Domain/SupportedCurrenciesTests.cs tests/Conscia.Tests.Unit/Domain/TransactionCategoriesTests.cs
git commit -m "feat: add SupportedCurrencies and TransactionCategories domain constants"
```

---

### Task 2: ConstantsGen Tool

**Files:**
- Create: `tools/ConstantsGen/ConstantsGen.csproj`
- Create: `tools/ConstantsGen/Metadata/CurrencyMetadata.cs`
- Create: `tools/ConstantsGen/Writers/DartWriter.cs`
- Create: `tools/ConstantsGen/Program.cs`

- [ ] **Step 1: Create project file**

```xml
<!-- tools/ConstantsGen/ConstantsGen.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <RootNamespace>ConstantsGen</RootNamespace>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\Conscia.Domain\Conscia.Domain.csproj" />
  </ItemGroup>
</Project>
```

- [ ] **Step 2: Create `CurrencyMetadata.cs`**

```csharp
// tools/ConstantsGen/Metadata/CurrencyMetadata.cs
namespace ConstantsGen.Metadata;

public static class CurrencyMetadata
{
    // (name, symbol, flag emoji)
    public static readonly Dictionary<string, (string Name, string Symbol, string Flag)> Map = new()
    {
        ["AED"] = ("UAE Dirham", "د.إ", "🇦🇪"),
        ["AFN"] = ("Afghan Afghani", "؋", "🇦🇫"),
        ["ALL"] = ("Albanian Lek", "L", "🇦🇱"),
        ["AMD"] = ("Armenian Dram", "֏", "🇦🇲"),
        ["ARS"] = ("Argentine Peso", "$", "🇦🇷"),
        ["AUD"] = ("Australian Dollar", "A$", "🇦🇺"),
        ["AWG"] = ("Aruban Florin", "ƒ", "🇦🇼"),
        ["AZN"] = ("Azerbaijani Manat", "₼", "🇦🇿"),
        ["BAM"] = ("Bosnia-Herzegovina Convertible Mark", "KM", "🇧🇦"),
        ["BBD"] = ("Barbadian Dollar", "$", "🇧🇧"),
        ["BDT"] = ("Bangladeshi Taka", "৳", "🇧🇩"),
        ["BGN"] = ("Bulgarian Lev", "лв", "🇧🇬"),
        ["BHD"] = ("Bahraini Dinar", ".د.ب", "🇧🇭"),
        ["BND"] = ("Brunei Dollar", "$", "🇧🇳"),
        ["BOB"] = ("Bolivian Boliviano", "Bs.", "🇧🇴"),
        ["BRL"] = ("Brazilian Real", "R$", "🇧🇷"),
        ["BWP"] = ("Botswanan Pula", "P", "🇧🇼"),
        ["BYN"] = ("Belarusian Ruble", "Br", "🇧🇾"),
        ["CAD"] = ("Canadian Dollar", "CA$", "🇨🇦"),
        ["CHF"] = ("Swiss Franc", "CHF", "🇨🇭"),
        ["CLP"] = ("Chilean Peso", "$", "🇨🇱"),
        ["CNY"] = ("Chinese Yuan", "¥", "🇨🇳"),
        ["COP"] = ("Colombian Peso", "$", "🇨🇴"),
        ["CRC"] = ("Costa Rican Colón", "₡", "🇨🇷"),
        ["CUP"] = ("Cuban Peso", "$", "🇨🇺"),
        ["CZK"] = ("Czech Koruna", "Kč", "🇨🇿"),
        ["DKK"] = ("Danish Krone", "kr", "🇩🇰"),
        ["DOP"] = ("Dominican Peso", "$", "🇩🇴"),
        ["DZD"] = ("Algerian Dinar", "د.ج", "🇩🇿"),
        ["EGP"] = ("Egyptian Pound", "£", "🇪🇬"),
        ["ETB"] = ("Ethiopian Birr", "Br", "🇪🇹"),
        ["EUR"] = ("Euro", "€", "🇪🇺"),
        ["FJD"] = ("Fijian Dollar", "$", "🇫🇯"),
        ["GBP"] = ("British Pound", "£", "🇬🇧"),
        ["GEL"] = ("Georgian Lari", "₾", "🇬🇪"),
        ["GHS"] = ("Ghanaian Cedi", "₵", "🇬🇭"),
        ["GTQ"] = ("Guatemalan Quetzal", "Q", "🇬🇹"),
        ["GYD"] = ("Guyanaese Dollar", "$", "🇬🇾"),
        ["HKD"] = ("Hong Kong Dollar", "HK$", "🇭🇰"),
        ["HNL"] = ("Honduran Lempira", "L", "🇭🇳"),
        ["HTG"] = ("Haitian Gourde", "G", "🇭🇹"),
        ["HUF"] = ("Hungarian Forint", "Ft", "🇭🇺"),
        ["IDR"] = ("Indonesian Rupiah", "Rp", "🇮🇩"),
        ["ILS"] = ("Israeli New Shekel", "₪", "🇮🇱"),
        ["INR"] = ("Indian Rupee", "₹", "🇮🇳"),
        ["IQD"] = ("Iraqi Dinar", "ع.د", "🇮🇶"),
        ["IRR"] = ("Iranian Rial", "﷼", "🇮🇷"),
        ["ISK"] = ("Icelandic Króna", "kr", "🇮🇸"),
        ["JMD"] = ("Jamaican Dollar", "$", "🇯🇲"),
        ["JOD"] = ("Jordanian Dinar", "JD", "🇯🇴"),
        ["JPY"] = ("Japanese Yen", "¥", "🇯🇵"),
        ["KES"] = ("Kenyan Shilling", "KSh", "🇰🇪"),
        ["KGS"] = ("Kyrgystani Som", "лв", "🇰🇬"),
        ["KHR"] = ("Cambodian Riel", "៛", "🇰🇭"),
        ["KWD"] = ("Kuwaiti Dinar", "KD", "🇰🇼"),
        ["KZT"] = ("Kazakhstani Tenge", "₸", "🇰🇿"),
        ["LAK"] = ("Laotian Kip", "₭", "🇱🇦"),
        ["LBP"] = ("Lebanese Pound", "£", "🇱🇧"),
        ["LKR"] = ("Sri Lankan Rupee", "₨", "🇱🇰"),
        ["MAD"] = ("Moroccan Dirham", "MAD", "🇲🇦"),
        ["MDL"] = ("Moldovan Leu", "L", "🇲🇩"),
        ["MGA"] = ("Malagasy Ariary", "Ar", "🇲🇬"),
        ["MKD"] = ("Macedonian Denar", "ден", "🇲🇰"),
        ["MMK"] = ("Myanmar Kyat", "K", "🇲🇲"),
        ["MNT"] = ("Mongolian Tugrik", "₮", "🇲🇳"),
        ["MUR"] = ("Mauritian Rupee", "₨", "🇲🇺"),
        ["MVR"] = ("Maldivian Rufiyaa", "Rf", "🇲🇻"),
        ["MXN"] = ("Mexican Peso", "MX$", "🇲🇽"),
        ["MYR"] = ("Malaysian Ringgit", "RM", "🇲🇾"),
        ["MZN"] = ("Mozambican Metical", "MT", "🇲🇿"),
        ["NAD"] = ("Namibian Dollar", "$", "🇳🇦"),
        ["NGN"] = ("Nigerian Naira", "₦", "🇳🇬"),
        ["NIO"] = ("Nicaraguan Córdoba", "C$", "🇳🇮"),
        ["NOK"] = ("Norwegian Krone", "kr", "🇳🇴"),
        ["NPR"] = ("Nepalese Rupee", "₨", "🇳🇵"),
        ["NZD"] = ("New Zealand Dollar", "NZ$", "🇳🇿"),
        ["OMR"] = ("Omani Rial", "﷼", "🇴🇲"),
        ["PAB"] = ("Panamanian Balboa", "B/.", "🇵🇦"),
        ["PEN"] = ("Peruvian Sol", "S/.", "🇵🇪"),
        ["PHP"] = ("Philippine Peso", "₱", "🇵🇭"),
        ["PKR"] = ("Pakistani Rupee", "₨", "🇵🇰"),
        ["PLN"] = ("Polish Zloty", "zł", "🇵🇱"),
        ["PYG"] = ("Paraguayan Guarani", "Gs", "🇵🇾"),
        ["QAR"] = ("Qatari Rial", "﷼", "🇶🇦"),
        ["RON"] = ("Romanian Leu", "lei", "🇷🇴"),
        ["RSD"] = ("Serbian Dinar", "din", "🇷🇸"),
        ["SAR"] = ("Saudi Riyal", "﷼", "🇸🇦"),
        ["SEK"] = ("Swedish Krona", "kr", "🇸🇪"),
        ["SGD"] = ("Singapore Dollar", "S$", "🇸🇬"),
        ["SRD"] = ("Surinamese Dollar", "$", "🇸🇷"),
        ["THB"] = ("Thai Baht", "฿", "🇹🇭"),
        ["TJS"] = ("Tajikistani Somoni", "SM", "🇹🇯"),
        ["TND"] = ("Tunisian Dinar", "DT", "🇹🇳"),
        ["TRY"] = ("Turkish Lira", "₺", "🇹🇷"),
        ["TTD"] = ("Trinidad & Tobago Dollar", "$", "🇹🇹"),
        ["TWD"] = ("New Taiwan Dollar", "NT$", "🇹🇼"),
        ["TZS"] = ("Tanzanian Shilling", "TSh", "🇹🇿"),
        ["UAH"] = ("Ukrainian Hryvnia", "₴", "🇺🇦"),
        ["UGX"] = ("Ugandan Shilling", "USh", "🇺🇬"),
        ["USD"] = ("US Dollar", "$", "🇺🇸"),
        ["UYU"] = ("Uruguayan Peso", "$U", "🇺🇾"),
        ["UZS"] = ("Uzbekistani Som", "лв", "🇺🇿"),
        ["VND"] = ("Vietnamese Dong", "₫", "🇻🇳"),
        ["WST"] = ("Samoan Tala", "WS$", "🇼🇸"),
        ["XAF"] = ("Central African CFA Franc", "FCFA", "🌍"),
        ["XOF"] = ("West African CFA Franc", "CFA", "🌍"),
        ["YER"] = ("Yemeni Rial", "﷼", "🇾🇪"),
        ["ZAR"] = ("South African Rand", "R", "🇿🇦"),
        ["ZMW"] = ("Zambian Kwacha", "ZK", "🇿🇲"),
    };
}
```

- [ ] **Step 3: Create `DartWriter.cs`**

```csharp
// tools/ConstantsGen/Writers/DartWriter.cs
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
```

- [ ] **Step 4: Create `Program.cs`**

```csharp
// tools/ConstantsGen/Program.cs
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
```

- [ ] **Step 5: Run the generator**

```bash
cd c:/Users/nearl/Repos/conscia
dotnet run --project tools/ConstantsGen
```

Expected output:
```
✅ app_constants.g.dart written (109 currencies, 14 expense categories, 8 income categories)
```

If you see `Missing metadata for currency code: XYZ`, add that code's entry to `CurrencyMetadata.Map` in Task 2 Step 2, then re-run.

- [ ] **Step 6: Verify the generated file**

```bash
head -30 app/lib/core/constants/generated/app_constants.g.dart
```

Expected: starts with `// GENERATED — do not edit by hand.` and contains `class FreemiumLimits`.

- [ ] **Step 7: Commit**

```bash
git add tools/ConstantsGen/ app/lib/core/constants/generated/
git commit -m "feat: add ConstantsGen tool and generated app_constants.g.dart"
```

---

### Task 3: IExchangeRateService + ExchangeRateService

**Files:**
- Create: `src/Conscia.Application/Interfaces/IExchangeRateService.cs`
- Create: `src/Conscia.Infrastructure/Services/ExchangeRateService.cs`
- Create: `tests/Conscia.Tests.Unit/Application/ExchangeRateServiceTests.cs`
- Modify: `src/Conscia.Api/Program.cs`

- [ ] **Step 1: Write failing test**

```csharp
// tests/Conscia.Tests.Unit/Application/ExchangeRateServiceTests.cs
using System.Net;
using System.Net.Http.Json;
using Conscia.Application.Interfaces;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Caching.Memory;
using Moq;
using Moq.Protected;

namespace Conscia.Tests.Unit.Application;

public class ExchangeRateServiceTests
{
    private static IExchangeRateService BuildService(HttpResponseMessage response)
    {
        var handler = new Mock<HttpMessageHandler>();
        handler.Protected()
            .Setup<Task<HttpResponseMessage>>("SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(response);

        var client = new HttpClient(handler.Object) { BaseAddress = new Uri("https://open.er-api.com") };
        var cache = new MemoryCache(new MemoryCacheOptions());
        return new ExchangeRateService(client, cache);
    }

    [Fact]
    public async Task GetRateAsync_ReturnsRate_WhenApiSucceeds()
    {
        var json = """{"result":"success","rates":{"USD":1.08,"GBP":0.86}}""";
        var svc = BuildService(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json")
        });

        var rate = await svc.GetRateAsync("EUR", "USD", default);

        Assert.NotNull(rate);
        Assert.Equal(1.08m, rate!.Value);
    }

    [Fact]
    public async Task GetRateAsync_ReturnsNull_WhenApiFails()
    {
        var svc = BuildService(new HttpResponseMessage(HttpStatusCode.ServiceUnavailable));

        var rate = await svc.GetRateAsync("EUR", "USD", default);

        Assert.Null(rate);
    }

    [Fact]
    public async Task GetRateAsync_ReturnsNull_WhenTargetCodeMissing()
    {
        var json = """{"result":"success","rates":{"USD":1.08}}""";
        var svc = BuildService(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json")
        });

        var rate = await svc.GetRateAsync("EUR", "XYZ", default);

        Assert.Null(rate);
    }
}
```

- [ ] **Step 2: Run — expect compile failure**

```bash
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~ExchangeRateService" 2>&1 | tail -5
```

Expected: build error — `IExchangeRateService` and `ExchangeRateService` not defined.

- [ ] **Step 3: Create `IExchangeRateService.cs`**

```csharp
// src/Conscia.Application/Interfaces/IExchangeRateService.cs
namespace Conscia.Application.Interfaces;

public interface IExchangeRateService
{
    /// <summary>
    /// Returns the exchange rate to convert <paramref name="fromCode"/> → <paramref name="toCode"/>.
    /// Returns null if the pair is unavailable (API down or unsupported code).
    /// </summary>
    Task<decimal?> GetRateAsync(string fromCode, string toCode, CancellationToken ct);
}
```

- [ ] **Step 4: Create `ExchangeRateService.cs`**

```csharp
// src/Conscia.Infrastructure/Services/ExchangeRateService.cs
using System.Text.Json;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Caching.Memory;

namespace Conscia.Infrastructure.Services;

public class ExchangeRateService : IExchangeRateService
{
    private readonly HttpClient _http;
    private readonly IMemoryCache _cache;
    private static readonly TimeSpan CacheTtl = TimeSpan.FromHours(24);

    public ExchangeRateService(HttpClient http, IMemoryCache cache)
    {
        _http = http;
        _cache = cache;
    }

    public async Task<decimal?> GetRateAsync(string fromCode, string toCode, CancellationToken ct)
    {
        if (string.Equals(fromCode, toCode, StringComparison.OrdinalIgnoreCase))
            return 1m;

        var cacheKey = $"fx:{fromCode.ToUpper()}";

        if (!_cache.TryGetValue(cacheKey, out Dictionary<string, decimal>? rates))
        {
            rates = await FetchRatesAsync(fromCode, ct);
            if (rates is not null)
                _cache.Set(cacheKey, rates, CacheTtl);
        }

        if (rates is null) return null;
        return rates.TryGetValue(toCode.ToUpper(), out var rate) ? rate : null;
    }

    private async Task<Dictionary<string, decimal>?> FetchRatesAsync(string fromCode, CancellationToken ct)
    {
        try
        {
            var response = await _http.GetAsync($"/v6/latest/{fromCode.ToUpper()}", ct);
            if (!response.IsSuccessStatusCode) return null;

            using var doc = await JsonDocument.ParseAsync(
                await response.Content.ReadAsStreamAsync(ct), cancellationToken: ct);

            if (!doc.RootElement.TryGetProperty("rates", out var ratesEl)) return null;

            var dict = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase);
            foreach (var prop in ratesEl.EnumerateObject())
            {
                if (prop.Value.TryGetDecimal(out var val))
                    dict[prop.Name] = val;
            }
            return dict;
        }
        catch
        {
            return null;
        }
    }
}
```

- [ ] **Step 5: Register in `Program.cs`**

In `src/Conscia.Api/Program.cs`, add the following in the `// --- Services ---` section (after the existing `builder.Services.AddScoped<IReceiptService, ReceiptService>();` line):

```csharp
// Exchange rates
builder.Services.AddMemoryCache();
builder.Services.AddHttpClient<IExchangeRateService, ExchangeRateService>(client =>
{
    client.BaseAddress = new Uri("https://open.er-api.com");
    client.Timeout = TimeSpan.FromSeconds(10);
});
```

Add the using at the top of `Program.cs`:
```csharp
using Conscia.Infrastructure.Services;
```

- [ ] **Step 6: Run tests — expect pass**

```bash
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~ExchangeRateService" 2>&1 | tail -5
```

Expected: `Passed! - Failed: 0, Passed: 3`

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Application/Interfaces/IExchangeRateService.cs \
        src/Conscia.Infrastructure/Services/ExchangeRateService.cs \
        src/Conscia.Api/Program.cs \
        tests/Conscia.Tests.Unit/Application/ExchangeRateServiceTests.cs
git commit -m "feat: add IExchangeRateService with open.er-api.com + 24h cache"
```

---

### Task 4: CreateTransactionDto + TransactionService Exchange Rate

**Files:**
- Modify: `src/Conscia.Application/DTOs/CreateTransactionDto.cs`
- Modify: `src/Conscia.Application/Services/TransactionService.cs`
- Modify: `tests/Conscia.Tests.Unit/Application/TransactionServiceTests.cs`

- [ ] **Step 1: Write failing tests**

Add these two test methods to `tests/Conscia.Tests.Unit/Application/TransactionServiceTests.cs`:

```csharp
// Add field at the top of the class:
private readonly Mock<IExchangeRateService> _fxMock = new();

// Change constructor to:
public TransactionServiceTests() =>
    _svc = new TransactionService(_repoMock.Object, _fxMock.Object, NullLogger<TransactionService>.Instance);

// Add these test methods:
[Fact]
public async Task CreateAsync_FetchesExchangeRate_WhenCurrencyDiffersFromBase()
{
    var userId = Guid.NewGuid();
    var dto = new CreateTransactionDto
    {
        Type = TransactionType.Expense,
        Amount = 100m,
        CurrencyCode = "EUR",
        BaseCurrencyCode = "USD",
        Category = "Travel",
        Date = DateTime.UtcNow
    };

    _fxMock.Setup(f => f.GetRateAsync("EUR", "USD", It.IsAny<CancellationToken>()))
        .ReturnsAsync(1.08m);
    _repoMock.Setup(r => r.AddWithOutboxAsync(It.IsAny<Transaction>(), It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
        .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);

    var result = await _svc.CreateAsync(userId, dto);

    Assert.Equal(1.08m, result.Amount.ExchangeRateToBase);
    _fxMock.Verify(f => f.GetRateAsync("EUR", "USD", It.IsAny<CancellationToken>()), Times.Once);
}

[Fact]
public async Task CreateAsync_UsesOverride_WhenExchangeRateOverrideProvided()
{
    var userId = Guid.NewGuid();
    var dto = new CreateTransactionDto
    {
        Type = TransactionType.Expense,
        Amount = 100m,
        CurrencyCode = "EUR",
        BaseCurrencyCode = "USD",
        ExchangeRateOverride = 0.92m,
        Category = "Travel",
        Date = DateTime.UtcNow
    };

    _repoMock.Setup(r => r.AddWithOutboxAsync(It.IsAny<Transaction>(), It.IsAny<OutboxEvent>(), It.IsAny<CancellationToken>()))
        .ReturnsAsync((Transaction t, OutboxEvent _, CancellationToken __) => t);

    var result = await _svc.CreateAsync(userId, dto);

    Assert.Equal(0.92m, result.Amount.ExchangeRateToBase);
    _fxMock.Verify(f => f.GetRateAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
}
```

- [ ] **Step 2: Run — expect compile failure**

```bash
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~TransactionService" 2>&1 | tail -5
```

Expected: build error — `BaseCurrencyCode` and `ExchangeRateOverride` not defined on DTO.

- [ ] **Step 3: Update `CreateTransactionDto.cs`**

Replace the file content with:

```csharp
// src/Conscia.Application/DTOs/CreateTransactionDto.cs
using Conscia.Domain.Enums;

namespace Conscia.Application.DTOs;

public class CreateTransactionDto
{
    public TransactionType Type { get; set; }
    public decimal Amount { get; set; }
    public string CurrencyCode { get; set; } = "USD";
    public string Category { get; set; } = string.Empty;
    public string? Merchant { get; set; }
    public DateTime Date { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? MerchantName { get; set; }
    /// <summary>User's preferred currency. Used to auto-fetch exchange rate when CurrencyCode differs.</summary>
    public string? BaseCurrencyCode { get; set; }
    /// <summary>Client-provided rate override. When set, skips API fetch.</summary>
    public decimal? ExchangeRateOverride { get; set; }
}
```

- [ ] **Step 4: Update `TransactionService.cs`**

Replace the constructor and `CreateAsync` method:

```csharp
// Add to using section:
using Conscia.Application.Interfaces;

// Replace the two private fields + constructor:
private readonly ITransactionRepository _repo;
private readonly IExchangeRateService _exchangeRateService;
private readonly ILogger<TransactionService> _logger;

public TransactionService(
    ITransactionRepository repo,
    IExchangeRateService exchangeRateService,
    ILogger<TransactionService> logger)
{
    _repo = repo;
    _exchangeRateService = exchangeRateService;
    _logger = logger;
}

// Replace CreateAsync:
public async Task<Transaction> CreateAsync(Guid userId, CreateTransactionDto dto, CancellationToken ct = default)
{
    decimal? exchangeRate = dto.ExchangeRateOverride;

    if (exchangeRate is null
        && dto.BaseCurrencyCode is not null
        && !string.Equals(dto.CurrencyCode, dto.BaseCurrencyCode, StringComparison.OrdinalIgnoreCase))
    {
        exchangeRate = await _exchangeRateService.GetRateAsync(dto.CurrencyCode, dto.BaseCurrencyCode, ct);
    }

    var transaction = new Transaction
    {
        Id = Guid.NewGuid(),
        UserId = userId,
        Type = dto.Type,
        Amount = new Money(dto.Amount, dto.CurrencyCode, exchangeRate),
        Category = dto.Category,
        Merchant = dto.Merchant,
        Date = dto.Date,
        CreatedAt = DateTime.UtcNow
    };

    if (dto.Latitude.HasValue && dto.Longitude.HasValue)
    {
        transaction.Location = new Location
        {
            Latitude = dto.Latitude.Value,
            Longitude = dto.Longitude.Value,
            MerchantName = dto.MerchantName
        };
    }

    var outboxEvent = new OutboxEvent
    {
        Id = Guid.NewGuid(),
        AggregateId = transaction.Id,
        EventType = OutboxEventType.TransactionCreated,
        Payload = JsonSerializer.Serialize(new
        {
            TransactionId = transaction.Id,
            UserId = userId,
            Amount = dto.Amount,
            CurrencyCode = dto.CurrencyCode,
            Category = dto.Category
        }),
        CreatedAt = DateTime.UtcNow
    };

    var result = await _repo.AddWithOutboxAsync(transaction, outboxEvent, ct);
    _logger.LogInformation("Creating transaction {TransactionId} for user {UserId}, amount {Amount} {Currency}",
        transaction.Id, userId, dto.Amount, dto.CurrencyCode);
    return result;
}
```

- [ ] **Step 5: Fix `TestWebAppFactory.cs` — `TransactionService` now requires `IExchangeRateService`**

In `tests/Conscia.Tests.Unit/Api/TestWebAppFactory.cs`, add to the mock fields:

```csharp
public Mock<IExchangeRateService> ExchangeRateServiceMock { get; } = new();
```

And in `ConfigureWebHost`, after the existing `ReplaceService` calls:

```csharp
ReplaceService<IExchangeRateService>(services, ExchangeRateServiceMock.Object);
```

- [ ] **Step 6: Run all unit tests — expect pass**

```bash
dotnet test tests/Conscia.Tests.Unit 2>&1 | tail -10
```

Expected: all tests pass (check `Failed: 0`).

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Application/DTOs/CreateTransactionDto.cs \
        src/Conscia.Application/Services/TransactionService.cs \
        tests/Conscia.Tests.Unit/Application/TransactionServiceTests.cs \
        tests/Conscia.Tests.Unit/Api/TestWebAppFactory.cs
git commit -m "feat: auto-fetch exchange rate in TransactionService; support client override"
```

---

### Task 5: ExchangeRateEndpoints

**Files:**
- Create: `src/Conscia.Api/Endpoints/ExchangeRateEndpoints.cs`
- Modify: `src/Conscia.Api/Program.cs`
- Create: `tests/Conscia.Tests.Unit/Api/ExchangeRateEndpointTests.cs`

- [ ] **Step 1: Write failing test**

```csharp
// tests/Conscia.Tests.Unit/Api/ExchangeRateEndpointTests.cs
using System.Net;
using System.Net.Http.Headers;
using Conscia.Application.Interfaces;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class ExchangeRateEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;

    public ExchangeRateEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());
    }

    [Fact]
    public async Task GetRate_ReturnsOk_WhenRateAvailable()
    {
        _factory.ExchangeRateServiceMock
            .Setup(s => s.GetRateAsync("EUR", "USD", It.IsAny<CancellationToken>()))
            .ReturnsAsync(1.0857m);

        var response = await _client.GetAsync("/api/v1/exchange-rates/EUR/USD");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("1.0857", body);
        Assert.Contains("EUR", body);
        Assert.Contains("USD", body);
    }

    [Fact]
    public async Task GetRate_Returns404_WhenRateUnavailable()
    {
        _factory.ExchangeRateServiceMock
            .Setup(s => s.GetRateAsync("EUR", "XYZ", It.IsAny<CancellationToken>()))
            .ReturnsAsync((decimal?)null);

        var response = await _client.GetAsync("/api/v1/exchange-rates/EUR/XYZ");

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetRate_Returns401_WhenUnauthenticated()
    {
        var anonClient = _factory.CreateClient();
        var response = await anonClient.GetAsync("/api/v1/exchange-rates/EUR/USD");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
```

- [ ] **Step 2: Run — expect compile failure**

```bash
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~ExchangeRateEndpoint" 2>&1 | tail -5
```

Expected: test project builds but runtime error since endpoint doesn't exist yet — or 404 from the test.

- [ ] **Step 3: Create `ExchangeRateEndpoints.cs`**

```csharp
// src/Conscia.Api/Endpoints/ExchangeRateEndpoints.cs
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class ExchangeRateEndpoints
{
    public static IEndpointRouteBuilder MapExchangeRateEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/exchange-rates")
            .RequireAuthorization()
            .WithTags("ExchangeRates");

        group.MapGet("/{from}/{to}", async (string from, string to, IExchangeRateService svc, CancellationToken ct) =>
        {
            var rate = await svc.GetRateAsync(from, to, ct);
            return rate is null
                ? Results.NotFound(new { error = $"Rate unavailable for {from.ToUpper()}/{to.ToUpper()}" })
                : Results.Ok(new { from = from.ToUpper(), to = to.ToUpper(), rate });
        });

        return app;
    }
}
```

- [ ] **Step 4: Register in `Program.cs`**

In `src/Conscia.Api/Program.cs`, after `app.MapInsightsEndpoints()...`, add:

```csharp
app.MapExchangeRateEndpoints().RequireRateLimiting("standard");
```

- [ ] **Step 5: Run tests — expect pass**

```bash
dotnet test tests/Conscia.Tests.Unit --filter "FullyQualifiedName~ExchangeRateEndpoint" 2>&1 | tail -5
```

Expected: `Passed! - Failed: 0, Passed: 3`

- [ ] **Step 6: Run full test suite**

```bash
dotnet test tests/Conscia.Tests.Unit 2>&1 | tail -10
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add src/Conscia.Api/Endpoints/ExchangeRateEndpoints.cs \
        src/Conscia.Api/Program.cs \
        tests/Conscia.Tests.Unit/Api/ExchangeRateEndpointTests.cs
git commit -m "feat: add GET /api/v1/exchange-rates/{from}/{to} endpoint"
```

---

### Task 6: Flutter — Migrate to Generated Constants

**Files:**
- Delete: `app/lib/core/constants/tier_limits.dart`
- Delete: `app/lib/core/constants/currencies.dart`
- Modify: `app/lib/providers/user_provider.dart`
- Modify: `app/lib/screens/transactions/widgets/category_picker.dart`
- Modify: `app/lib/core/constants/category_icons.dart`
- Any other file importing the deleted files (found in Step 1)

- [ ] **Step 1: Find all files importing the deleted constants**

```bash
cd c:/Users/nearl/Repos/conscia/app
grep -rl "tier_limits.dart\|currencies.dart" lib/
```

Note every file printed — each will need its import updated.

- [ ] **Step 2: Update `user_provider.dart`**

Replace the entire file:

```dart
// app/lib/providers/user_provider.dart
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/generated/app_constants.g.dart';
import '../core/network/dio_client.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(dioProvider));
});

final currentUserProvider = FutureProvider<UserProfile>((ref) async {
  final service = ref.watch(userServiceProvider);
  return service.getProfile();
});

({String currency, String locale}) deviceDefaults() {
  final deviceLocale = _bestDeviceLocale();
  final country = _resolveCountryCode(deviceLocale);
  return (
    currency: _currencyFromCountry(country),
    locale: '${deviceLocale.languageCode}_$country',
  );
}

String _currencyFromCountry(String countryCode) {
  const countryToCurrency = {
    'US': 'USD', 'EU': 'EUR', 'GB': 'GBP', 'JP': 'JPY', 'CH': 'CHF',
    'CA': 'CAD', 'AU': 'AUD', 'CN': 'CNY', 'IN': 'INR', 'MX': 'MXN',
    'BR': 'BRL', 'KR': 'KRW', 'SE': 'SEK', 'NO': 'NOK', 'DK': 'DKK',
    'SG': 'SGD', 'HK': 'HKD', 'NZ': 'NZD', 'ZA': 'ZAR', 'TR': 'TRY',
    'PL': 'PLN', 'TH': 'THB', 'PH': 'PHP', 'ID': 'IDR', 'MY': 'MYR',
    'CZ': 'CZK', 'HU': 'HUF', 'RO': 'RON', 'IL': 'ILS', 'AE': 'AED',
    'SA': 'SAR', 'CO': 'COP', 'AR': 'ARS', 'CL': 'CLP', 'PE': 'PEN',
    'VN': 'VND', 'UA': 'UAH', 'EG': 'EGP', 'NG': 'NGN', 'PK': 'PKR',
  };
  return countryToCurrency[countryCode] ?? 'USD';
}

ui.Locale _bestDeviceLocale() {
  final dispatcher = ui.PlatformDispatcher.instance;
  return dispatcher.locales.isNotEmpty
      ? dispatcher.locales.first
      : dispatcher.locale;
}

String _resolveCountryCode(ui.Locale locale) {
  final normalizedCountry = locale.countryCode?.toUpperCase();
  if (normalizedCountry != null && normalizedCountry.isNotEmpty) {
    return normalizedCountry;
  }

  const languageToCountry = {
    'en': 'US', 'es': 'ES', 'fr': 'FR', 'de': 'DE', 'pt': 'BR',
    'ja': 'JP', 'zh': 'CN', 'ko': 'KR', 'th': 'TH', 'id': 'ID',
    'ms': 'MY', 'tl': 'PH', 'fil': 'PH',
  };

  return languageToCountry[locale.languageCode.toLowerCase()] ?? 'US';
}

final userPreferencesProvider =
    Provider<({String currency, String locale})>((ref) {
  final user = ref.watch(currentUserProvider);
  final defaults = deviceDefaults();
  return user.maybeWhen(
    data: (profile) => (currency: profile.currencyCode, locale: profile.locale),
    orElse: () => defaults,
  );
});
```

- [ ] **Step 3: Update `category_picker.dart`**

Replace the two hardcoded `const` lists at the top with imports from the generated file. The widget definition itself is unchanged.

```dart
// app/lib/screens/transactions/widgets/category_picker.dart
import 'package:flutter/material.dart';

import '../../../core/constants/generated/app_constants.g.dart';

class CategoryData {
  final String name;
  final IconData icon;
  const CategoryData(this.name, this.icon);
}

// Remove: const expenseCategories = [...] and const incomeCategories = [...]
// expenseCategories and incomeCategories are now imported from app_constants.g.dart

class CategoryPicker extends StatefulWidget {
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool isExpense;
  final int maxVisible;

  const CategoryPicker({
    super.key,
    this.selected,
    required this.onSelected,
    this.isExpense = true,
    this.maxVisible = 9,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  bool _expanded = false;

  List<CategoryData> get _categories {
    final names = widget.isExpense ? expenseCategories : incomeCategories;
    return names.map((n) => CategoryData(n, CategoryIcons.forCategory(n))).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categories = _categories;
    final visible = _expanded
        ? categories
        : categories.take(widget.maxVisible).toList();
    final hasMore = categories.length > widget.maxVisible && !_expanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cat in visible)
              ChoiceChip(
                avatar: Icon(cat.icon, size: 18),
                label: Text(cat.name),
                selected: widget.selected == cat.name,
                onSelected: (_) => widget.onSelected(cat.name),
                selectedColor: colors.primaryContainer,
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: widget.selected == cat.name
                          ? colors.onPrimaryContainer
                          : colors.onSurfaceVariant,
                    ),
              ),
            if (hasMore)
              ActionChip(
                label: const Text('More...'),
                onPressed: () => setState(() => _expanded = true),
              ),
          ],
        ),
      ],
    );
  }
}
```

Also add import for `CategoryIcons` since it's now used inside `_categories`:
```dart
import '../../../core/constants/category_icons.dart';
```

- [ ] **Step 4: Update any other files found in Step 1**

For each file importing `tier_limits.dart`:
- Remove: `import '../core/constants/tier_limits.dart';` (adjust path depth as needed)
- Add: `import '../core/constants/generated/app_constants.g.dart';` (adjust path depth)
- Replace any `TierLimits.freeBudgetCategories` → `FreemiumLimits.freeBudgetCategories` (etc.)

For each file importing `currencies.dart` (other than `user_provider.dart` already done):
- Remove the `currencies.dart` import
- Add: `import '../core/constants/generated/app_constants.g.dart';`
- Replace `Currencies.all` → `supportedCurrencies`
- Replace `CurrencyInfo(code: ..., name: ..., ...)` → `CurrencyInfo(code, name, symbol, flag)` (positional constructor)

- [ ] **Step 5: Delete the old files**

```bash
rm app/lib/core/constants/tier_limits.dart
rm app/lib/core/constants/currencies.dart
```

- [ ] **Step 6: Analyze — expect zero errors**

```bash
cd c:/Users/nearl/Repos/conscia/app
flutter analyze lib/ 2>&1 | grep -E "error|warning"
```

Expected: no errors and no warnings (only pre-existing `info` items are acceptable).

- [ ] **Step 7: Commit**

```bash
cd c:/Users/nearl/Repos/conscia
git add app/lib/ 
git commit -m "feat: migrate Flutter to generated constants; remove tier_limits.dart and currencies.dart"
```

---

### Task 7: Flutter — Exchange Rate Provider & Transaction Form

**Files:**
- Create: `app/lib/providers/exchange_rate_provider.dart`
- Modify: `app/lib/models/transaction.dart`
- Modify: `app/lib/services/transaction_service.dart`
- Modify: `app/lib/screens/transactions/transaction_form_screen.dart`

- [ ] **Step 1: Create `exchange_rate_provider.dart`**

```dart
// app/lib/providers/exchange_rate_provider.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';

/// Returns the live exchange rate for [from] → [to].
/// Returns null on error or when currencies are the same.
final exchangeRateProvider =
    FutureProvider.family<double?, (String from, String to)>((ref, pair) async {
  final (from, to) = pair;
  if (from == to) return null;
  try {
    final dio = ref.watch(dioProvider);
    final response = await dio.get<Map<String, dynamic>>(
      'exchange-rates/$from/$to',
    );
    final rate = response.data?['rate'];
    if (rate is num) return rate.toDouble();
    return null;
  } on DioException {
    return null;
  }
});
```

- [ ] **Step 2: Update `transaction.dart` — add `exchangeRateToBase`**

```dart
// app/lib/models/transaction.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType {
  @JsonValue('expense')
  expense,
  @JsonValue('income')
  income,
}

@freezed
class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required TransactionType type,
    required double amount,
    required String currencyCode,
    required String category,
    String? merchant,
    required DateTime date,
    String? location,
    @Default(0) int regretLevel,
    String? notes,
    required DateTime createdAt,
    double? exchangeRateToBase,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
```

- [ ] **Step 3: Regenerate Freezed files**

```bash
cd c:/Users/nearl/Repos/conscia/app
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5
```

Expected: `[INFO] Succeeded after ...`

- [ ] **Step 4: Update `CreateTransactionDto` in `transaction_service.dart`**

In `app/lib/services/transaction_service.dart`, update the `CreateTransactionDto` class:

```dart
class CreateTransactionDto {
  final double amount;
  final String currencyCode;
  final String category;
  final String merchant;
  final String type;
  final DateTime date;
  final String? baseCurrencyCode;
  final double? exchangeRateOverride;

  const CreateTransactionDto({
    required this.amount,
    required this.currencyCode,
    required this.category,
    required this.merchant,
    required this.type,
    required this.date,
    this.baseCurrencyCode,
    this.exchangeRateOverride,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'amount': amount,
      'currencyCode': currencyCode,
      'category': category,
      'merchant': merchant,
      'type': _capitalizeType(type),
      'date': date.toIso8601String(),
    };
    if (baseCurrencyCode != null) json['baseCurrencyCode'] = baseCurrencyCode;
    if (exchangeRateOverride != null) json['exchangeRateOverride'] = exchangeRateOverride;
    return json;
  }

  static String _capitalizeType(String t) =>
      t.isEmpty ? t : '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
}
```

- [ ] **Step 5: Update `transaction_form_screen.dart`**

Add state fields and imports at the top of `_TransactionFormScreenState`:

```dart
// Add these imports at the top of the file:
import '../../providers/exchange_rate_provider.dart';

// Add these state fields inside _TransactionFormScreenState:
final _exchangeRateController = TextEditingController();
```

Update `dispose()`:
```dart
@override
void dispose() {
  _amountController.dispose();
  _merchantController.dispose();
  _notesController.dispose();
  _exchangeRateController.dispose();
  super.dispose();
}
```

Update `_submit()` — replace the `CreateTransactionDto(...)` call:

```dart
final userCurrency = ref.read(userPreferencesProvider).currency;
final rateOverride = double.tryParse(_exchangeRateController.text);

final dto = CreateTransactionDto(
  amount: double.parse(_amountController.text),
  currencyCode: _currencyCode,
  category: _selectedCategory!,
  merchant: _merchantController.text,
  type: _isExpense ? 'expense' : 'income',
  date: _selectedDate,
  baseCurrencyCode: userCurrency,
  exchangeRateOverride: rateOverride,
);
```

Add the exchange rate field inside `build()`, after the `AmountInputField` and before `CategoryPicker`. Place it inside a `Consumer` so it can watch the provider:

```dart
// After AmountInputField SizedBox(height: 16):
Consumer(
  builder: (context, ref, _) {
    final userCurrency = ref.watch(userPreferencesProvider).currency;
    if (_currencyCode == userCurrency) return const SizedBox.shrink();

    final rateAsync = ref.watch(
      exchangeRateProvider((_currencyCode, userCurrency)),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: rateAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (_, __) => const SizedBox.shrink(),
        data: (liveRate) => TextField(
          controller: _exchangeRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Exchange rate (optional)',
            hintText: liveRate != null
                ? liveRate.toStringAsFixed(4)
                : 'Enter rate manually',
            helperText: liveRate != null
                ? 'Leave blank to use live rate (1 $_currencyCode = ${liveRate.toStringAsFixed(4)} $userCurrency)'
                : 'Live rate unavailable — enter manually or leave blank',
          ),
        ),
      ),
    );
  },
),
```

- [ ] **Step 6: Analyze — expect zero errors**

```bash
cd c:/Users/nearl/Repos/conscia/app
flutter analyze lib/ 2>&1 | grep -E "error|warning"
```

Expected: no errors, no warnings.

- [ ] **Step 7: Commit**

```bash
cd c:/Users/nearl/Repos/conscia
git add app/lib/providers/exchange_rate_provider.dart \
        app/lib/models/transaction.dart \
        app/lib/models/transaction.freezed.dart \
        app/lib/models/transaction.g.dart \
        app/lib/services/transaction_service.dart \
        app/lib/screens/transactions/transaction_form_screen.dart
git commit -m "feat: exchange rate provider, override field in transaction form, model field"
```

---

### Task 8: CI Drift Check

**Files:**
- Create: `.github/workflows/constants-drift.yml`

- [ ] **Step 1: Create the workflow file**

```yaml
# .github/workflows/constants-drift.yml
name: Constants drift check

on:
  pull_request:
    paths:
      - 'src/Conscia.Domain/**'
      - 'tools/ConstantsGen/**'

jobs:
  drift:
    name: Verify app_constants.g.dart is up to date
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '9.x'

      - name: Regenerate constants
        run: dotnet run --project tools/ConstantsGen

      - name: Fail on drift
        run: |
          if ! git diff --exit-code app/lib/core/constants/generated/app_constants.g.dart; then
            echo ""
            echo "❌ app_constants.g.dart is out of sync with Conscia.Domain."
            echo "   Run locally: dotnet run --project tools/ConstantsGen"
            echo "   Then commit the updated app_constants.g.dart."
            exit 1
          fi
          echo "✅ app_constants.g.dart is up to date."
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/constants-drift.yml
git commit -m "ci: add constants drift check — fails if app_constants.g.dart is out of sync"
```

- [ ] **Step 3: Verify the workflow file is valid YAML**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/constants-drift.yml'))" && echo "Valid YAML"
```

Expected: `Valid YAML`

---

## Self-Review

### Spec coverage check

| Spec section | Covered by task |
|---|---|
| `SupportedCurrencies.cs` | Task 1 |
| `TransactionCategories.cs` | Task 1 |
| ConstantsGen tool (project, metadata, writer, program) | Task 2 |
| Generated `app_constants.g.dart` | Task 2 |
| `IExchangeRateService` | Task 3 |
| `ExchangeRateService` (open.er-api.com, 24h cache) | Task 3 |
| DTO rename + `BaseCurrencyCode` | Task 4 |
| `TransactionService` auto-fetch logic | Task 4 |
| `GET /exchange-rates/{from}/{to}` | Task 5 |
| Delete `tier_limits.dart`, `currencies.dart` | Task 6 |
| Migrate Flutter imports | Task 6 |
| `exchangeRateProvider` | Task 7 |
| `exchangeRateToBase` on `Transaction` model | Task 7 |
| Exchange rate override field in form (live placeholder) | Task 7 |
| CI drift check | Task 8 |

### Type consistency check

- `IExchangeRateService.GetRateAsync` returns `Task<decimal?>` (Task 3) → consumed as `decimal?` in `TransactionService` (Task 4) ✅
- `ExchangeRateService` mock exposed on `TestWebAppFactory` (Task 4) → used in `ExchangeRateEndpointTests` (Task 5) ✅
- `CreateTransactionDto.BaseCurrencyCode` (Task 4) → sent from Flutter `CreateTransactionDto.baseCurrencyCode` (Task 7) ✅
- `exchangeRateProvider` returns `double?` (Task 7) → used as `liveRate` in form (Task 7) ✅
- Generated `expenseCategories`/`incomeCategories` are `List<String>` (Task 2) → consumed in `category_picker.dart` as `String` lists (Task 6) ✅
