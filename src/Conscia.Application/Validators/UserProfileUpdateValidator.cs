using Conscia.Application.DTOs;
using FluentValidation;

namespace Conscia.Application.Validators;

public class UserProfileUpdateValidator : AbstractValidator<UserProfileUpdateDto>
{
    // Mapping of country codes to their primary currency codes for validation purposes
    // see currencies.dart for the full list of supported currencies in the app
    private readonly Dictionary<string, string> _countryToCurrency = new()
    {
        { "US" , "USD" }, { "GB", "GBP" }, { "MX", "MXN" }, { "ES", "EUR" },
        { "FR", "EUR" }, { "DE", "EUR" }, { "IT", "EUR" }, { "NL", "EUR" },
        { "BE", "EUR" }, { "AT", "EUR" }, { "IE", "EUR" }, { "PT", "EUR" },
        { "FI", "EUR" }, { "GR", "EUR" }, { "SK", "EUR" }, { "SI", "EUR" },
        { "LT", "EUR" }, { "LV", "EUR" }, { "EE", "EUR" }, { "MT", "EUR" },
        { "CY", "EUR" }, { "LU", "EUR" },
        { "JP", "JPY" }, { "CN", "CNY" }, { "BR", "BRL" }, { "CA", "CAD" },
        { "AU", "AUD" }, { "IN", "INR" }, { "KR", "KRW" }, { "PH", "PHP" },
        { "SG", "SGD" }, { "TH", "THB" }, { "ID", "IDR" }, { "MY", "MYR" },
        { "NZ", "NZD" }, { "CH", "CHF" }, { "SE", "SEK" }, { "NO", "NOK" },
        { "DK", "DKK" }, { "PL", "PLN" }, { "CZ", "CZK" }, { "HU", "HUF" },
        { "RO", "RON" }, { "ZA", "ZAR" }, { "AE", "AED" }, { "SA", "SAR" },
    };

    public UserProfileUpdateValidator()
    {
        RuleFor(x => x)
            .Must(dto =>
                dto.PreferredCurrency is not null ||
                dto.Locale is not null ||
                dto.SpendingPersonality is not null ||
                dto.IncomeRange is not null ||
                dto.OccupationType is not null ||
                dto.HouseholdSize is not null)
            .WithMessage("At least one field must be provided");

        RuleFor(x => x.PreferredCurrency)
            .Length(3)
            .When(x => x.PreferredCurrency is not null)
            .WithMessage("Currency code must be a 3-letter ISO code");

        RuleFor(x => x.PreferredCurrency)
            .Must(c => c is null || _countryToCurrency.ContainsValue(c.ToUpperInvariant()))
            .WithMessage("Unsupported currency code");

        RuleFor(x => x.Locale)
            .MaximumLength(10)
            .When(x => x.Locale is not null);
    }
}
