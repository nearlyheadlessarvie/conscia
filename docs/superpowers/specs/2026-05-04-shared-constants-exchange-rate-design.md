# Design: Shared Constants Generator & Exchange Rate Handling

**Date:** 2026-05-04
**Status:** Approved
**Scope:** `tools/ConstantsGen/`, `src/Conscia.Domain/`, `src/Conscia.Application/`, `src/Conscia.Infrastructure/`, `src/Conscia.Api/`, `app/lib/`, `.github/workflows/`

---

## 1. Problem

Flutter and .NET each maintain their own copies of domain constants:

| Constant | Backend | Flutter | Risk |
|----------|---------|---------|------|
| `FreemiumLimits` | `FreemiumLimits.cs` | `tier_limits.dart` | Exact duplicate — silent drift if one is changed |
| `TransactionCategories` | Free-text (no list) | Hardcoded in `category_picker.dart` | Backend accepts values the UI never offers and vice versa |
| `SupportedCurrencies` | Any ISO 4217 (dynamic) | 35 hardcoded in `currencies.dart` | Flutter list is arbitrarily narrow |
| `RegretLevel` | `RegretLevel.cs` enum | Inline integers `0/1/2` in widgets | No enum in Flutter — magic numbers |
| `SubscriptionTier` | `SubscriptionTier.cs` enum | String comparisons (`"Premium"`) | Case-sensitive drift risk |

Additionally, `Money.ExchangeRateToBase` exists on the backend but is never populated — the Flutter client never sends a rate and the API never returns one.

---

## 2. Decision

**A .NET console tool (`tools/ConstantsGen`) reads `Conscia.Domain` directly and writes a single generated Dart file.** The tool is run manually; CI fails any PR where the generated file is out of sync with the domain source.

Exchange rate handling is designed alongside this work because it directly depends on the currency list and `Money` value object.

---

## 3. Architecture

```
src/Conscia.Domain/Constants/
    FreemiumLimits.cs              (exists — no changes)
    SupportedCurrencies.cs         (NEW — authoritative ~150-currency list)
    TransactionCategories.cs       (NEW — expense + income category lists)
    (existing enums: RegretLevel, SubscriptionTier, TransactionType)

src/Conscia.Application/
    Interfaces/IExchangeRateService.cs   (NEW)
    DTOs/CreateTransactionDto.cs         (MODIFY — rename field)

src/Conscia.Infrastructure/
    Services/ExchangeRateService.cs      (NEW — calls open.er-api.com, 24h cache)

src/Conscia.Api/
    Endpoints/ExchangeRateEndpoints.cs   (NEW — GET /api/v1/exchange-rates/{from}/{to})
    Program.cs                           (MODIFY — register new service + endpoint)

tools/ConstantsGen/
    ConstantsGen.csproj            references Conscia.Domain
    Program.cs                     entry point
    Writers/DartWriter.cs          builds the .dart string
    Metadata/CurrencyMetadata.cs   lookup: code → (name, symbol, flag emoji)

app/lib/core/constants/generated/
    app_constants.g.dart           GENERATED — do not edit by hand

app/lib/
    providers/exchange_rate_provider.dart     (NEW)
    screens/transactions/transaction_form_screen.dart  (MODIFY)
    services/transaction_service.dart                  (MODIFY)
    models/transaction.dart                            (MODIFY)
    (delete) core/constants/tier_limits.dart
    (delete) core/constants/currencies.dart
    (modify) screens/transactions/widgets/category_picker.dart
    (modify) core/constants/category_icons.dart

.github/workflows/
    constants-drift.yml            (NEW — CI drift check)
```

---

## 4. .NET Domain Additions

### `SupportedCurrencies.cs`

```csharp
namespace Conscia.Domain.Constants;

public static class SupportedCurrencies
{
    public static readonly IReadOnlyList<string> Codes = new[]
    {
        // ~150 most commonly used ISO 4217 codes
        "USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD", "CNY", "INR", "MXN",
        "BRL", "KRW", "SEK", "NOK", "DKK", "SGD", "HKD", "NZD", "ZAR", "TRY",
        "PLN", "THB", "PHP", "IDR", "MYR", "CZK", "HUF", "RON", "ILS", "AED",
        "SAR", "COP", "ARS", "CLP", "PEN", "VND", "UAH", "EGP", "NGN", "PKR",
        "BDT", "GHS", "KES", "MAD", "QAR", "KWD", "BHD", "OMR", "JOD", "LBP",
        "TWD", "LKR", "MMK", "KZT", "UZS", "AZN", "GEL", "AMD", "BYN", "MDL",
        "ISK", "HRK", "RSD", "MKD", "ALL", "BAM", "BGN", "DZD", "TND", "LYD",
        "ETB", "TZS", "UGX", "ZMW", "MZN", "BWP", "NAD", "MUR", "SCR", "MGA",
        "XOF", "XAF", "CDF", "SDG", "SOS", "DJF", "GMD", "GNF", "SLL", "LRD",
        "GTQ", "HNL", "NIO", "CRC", "PAB", "DOP", "CUP", "JMD", "TTD", "BBD",
        "BSD", "HTG", "BOB", "PYG", "UYU", "GYD", "SRD", "FJD", "PGK", "WST",
        "TOP", "VUV", "SBD", "AFN", "IRR", "IQD", "SYP",
        "YER", "NPR", "BTN", "MVR", "MNT", "KHR", "LAK", "BND", "TJS", "KGS"
        // Full list finalised during implementation — codes above are illustrative
    };
}
```

`Money.cs` validation stays as-is (accepts all ISO 4217 via `CultureInfo`). `SupportedCurrencies.Codes` is the curated UI list, not a validation constraint.

### `TransactionCategories.cs`

```csharp
namespace Conscia.Domain.Constants;

public static class TransactionCategories
{
    public static readonly IReadOnlyList<string> Expense = new[]
    {
        "Groceries", "Dining", "Transport", "Entertainment", "Games & Recreations",
        "Shopping", "Health", "Bills", "Education", "Travel", "Coffee",
        "Subscriptions", "Gift", "Other"
    };

    public static readonly IReadOnlyList<string> Income = new[]
    {
        "Salary", "Freelance", "Business", "Investment",
        "Rental Income", "Bonus", "Gift", "Other"
    };
}
```

Backend validators remain permissive (category is a non-empty string ≤ 100 chars). `TransactionCategories` is the authoritative UI list; the backend does not enforce it server-side to avoid breaking third-party integrations or API clients.

---

## 5. Generator Tool

### `ConstantsGen.csproj`

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net9.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <ProjectReference Include="..\..\src\Conscia.Domain\Conscia.Domain.csproj" />
  </ItemGroup>
</Project>
```

### `Program.cs` — responsibilities

1. Collect `FreemiumLimits` field values via direct const references
2. Collect enum member names from `TransactionType`, `RegretLevel`, `SubscriptionTier`
3. Collect `TransactionCategories.Expense` and `.Income` lists
4. Collect `SupportedCurrencies.Codes`, join with `CurrencyMetadata` lookup
5. Pass all data to `DartWriter`, write to `../../app/lib/core/constants/generated/app_constants.g.dart`
6. Print `✅ app_constants.g.dart written ({n} currencies, {n} expense categories, {n} income categories)`

### `CurrencyMetadata.cs`

Static dictionary mapping each code in `SupportedCurrencies.Codes` to `(Name, Symbol, Flag)`. This is presentation data — it lives in the tool, not in the domain.

```csharp
public static class CurrencyMetadata
{
    public static readonly Dictionary<string, (string Name, string Symbol, string Flag)> Map = new()
    {
        ["USD"] = ("US Dollar", "$", "🇺🇸"),
        ["EUR"] = ("Euro", "€", "🇪🇺"),
        ["GBP"] = ("British Pound", "£", "🇬🇧"),
        // ... all ~150 entries
    };
}
```

Any code in `SupportedCurrencies.Codes` without a metadata entry causes the generator to throw with a clear message, preventing silent missing entries.

### Run command

```bash
dotnet run --project tools/ConstantsGen
```

---

## 6. Generated Dart File

`app/lib/core/constants/generated/app_constants.g.dart`:

```dart
// GENERATED — do not edit by hand.
// Regenerate: dotnet run --project tools/ConstantsGen
// Source: Conscia.Domain + tools/ConstantsGen/Metadata/CurrencyMetadata.cs

// ── Freemium limits ──────────────────────────────────────────────
class FreemiumLimits {
  FreemiumLimits._();
  static const int freeBudgetCategories = 3;
  static const int freeAiAssistsPerMonth = 5;
  static const int freeReflectionsPerMonth = 10;
  static const int freeCurrencies = 1;
}

// ── Enums ────────────────────────────────────────────────────────
// Note: TransactionType is NOT generated here — it carries @JsonValue
// serialisation annotations in transaction.dart and must stay there.
// The generated RegretLevel and SubscriptionTier replace magic values in UI.
enum RegretLevel { worthIt, notSure, regret }
enum SubscriptionTier { free, premium }

// ── Categories ───────────────────────────────────────────────────
const List<String> expenseCategories = [
  'Groceries', 'Dining', 'Transport', 'Entertainment', 'Games & Recreations',
  'Shopping', 'Health', 'Bills', 'Education', 'Travel', 'Coffee',
  'Subscriptions', 'Gift', 'Other',
];

const List<String> incomeCategories = [
  'Salary', 'Freelance', 'Business', 'Investment',
  'Rental Income', 'Bonus', 'Gift', 'Other',
];

// ── Currencies ───────────────────────────────────────────────────
class CurrencyInfo {
  final String code;
  final String name;
  final String symbol;
  final String flag;
  const CurrencyInfo(this.code, this.name, this.symbol, this.flag);
}

const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo('USD', 'US Dollar', r'$', '🇺🇸'),
  CurrencyInfo('EUR', 'Euro', '€', '🇪🇺'),
  // ... ~150 entries
];
```

No Flutter framework imports — pure Dart. UI mappings (RegretLevel → Color, category → IconData) stay in their existing files and import from this file.

---

## 7. Exchange Rate Handling

### New interface — `IExchangeRateService`

```csharp
// Conscia.Application/Interfaces/IExchangeRateService.cs
public interface IExchangeRateService
{
    // Returns the rate to convert `fromCode` → `toCode`.
    // Returns null if the pair is unavailable (API down, unsupported code).
    Task<decimal?> GetRateAsync(string fromCode, string toCode, CancellationToken ct);
}
```

### Implementation — `ExchangeRateService`

- Calls `https://open.er-api.com/v6/latest/{fromCode}` (free, no API key, 170+ currencies)
- Caches each base-currency response in `IMemoryCache` with a 24-hour absolute expiry
- Returns `null` on any HTTP or parse failure (non-throwing — callers degrade gracefully)

### `CreateTransactionDto` change

```csharp
// Rename ExchangeRateToBase → ExchangeRateOverride to make intent explicit
public decimal? ExchangeRateOverride { get; init; }
```

`TransactionService.CreateAsync` logic:
```
if dto.CurrencyCode == user.PreferredCurrency
    → create Money(amount, code, exchangeRateToBase: null)
else if dto.ExchangeRateOverride has value
    → create Money(amount, code, exchangeRateToBase: override)
else
    → rate = await exchangeRateService.GetRateAsync(dto.CurrencyCode, user.PreferredCurrency)
    → create Money(amount, code, exchangeRateToBase: rate)  // null if API unavailable
```

### New endpoint — `ExchangeRateEndpoints`

```
GET /api/v1/exchange-rates/{from}/{to}
Auth: Bearer required
Response 200: { "from": "EUR", "to": "USD", "rate": 1.0857 }
Response 404: { "error": "Rate unavailable for EUR/USD" }  — when API is down or pair unsupported
```

Uses the same `IExchangeRateService` + cache — no extra API calls beyond what transaction creation already makes.

### Flutter changes

**New provider** `exchangeRateProvider(from, to)` — `FutureProvider.family` that calls `GET /exchange-rates/{from}/{to}`. Returns `double?`.

**Transaction form** — when `selectedCurrency ≠ userDefaultCurrency`:
- Show optional `TextFormField` labelled "Exchange rate"
- While provider is loading: show shimmer skeleton in the field
- On load: set placeholder text to live rate string (e.g. `"1.0857"`)
- Hint text: `"Leave blank to use live rate"`
- User can type an override; leaving blank sends `exchangeRateOverride: null` → backend uses fetched rate

**`CreateTransactionDto` in Flutter** (`transaction_service.dart`):
- Add `exchangeRateOverride: double?` to `toJson()` — only included when non-null

**`Transaction` model** (`transaction.dart`):
- Add `exchangeRateToBase: double?` — populated from API response so stored rate is visible in detail screen

---

## 8. Flutter Migration — Deleted/Modified Files

| File | Action | Detail |
|------|--------|--------|
| `core/constants/tier_limits.dart` | **Delete** | All importers switch to `app_constants.g.dart` |
| `core/constants/currencies.dart` | **Delete** | All importers switch to `app_constants.g.dart` |
| `core/constants/category_icons.dart` | **Modify** | Remove hardcoded category name strings; import `expenseCategories`/`incomeCategories` from generated file; add icons for new income categories (Business, Investment, Rental Income, Bonus) |
| `screens/transactions/widgets/category_picker.dart` | **Modify** | Remove hardcoded category lists; import from generated file |
| `providers/user_provider.dart` | **Modify** | `SubscriptionTier` string comparisons → generated enum |
| Any file importing `tier_limits.dart` | **Modify** | Swap import |
| Any file importing `currencies.dart` | **Modify** | Swap import |

---

## 9. CI Drift Check

`.github/workflows/constants-drift.yml`:

```yaml
name: Constants drift check
on:
  pull_request:
    paths:
      - 'src/Conscia.Domain/**'
      - 'tools/ConstantsGen/**'

jobs:
  drift:
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
          git diff --exit-code app/lib/core/constants/generated/app_constants.g.dart \
            || (echo "❌ app_constants.g.dart is out of sync. Run: dotnet run --project tools/ConstantsGen" && exit 1)
```

The workflow triggers only when Domain or ConstantsGen files change — not on every PR.

---

## 10. Out of Scope

- Adding backend category validation (server accepts any non-empty string ≤ 100 chars — stays permissive)
- Admin UI for managing currencies or categories
- Historical exchange rate lookup (rates are snapshotted at transaction creation time only)
- Budget cross-currency aggregation (budgets remain single-currency)
- The Flutter DRY pass (RegretLevel → Color mapping, etc.) — this is sub-project B
- The .NET DRY pass (typed DTOs, validation extension, etc.) — this is sub-project C
