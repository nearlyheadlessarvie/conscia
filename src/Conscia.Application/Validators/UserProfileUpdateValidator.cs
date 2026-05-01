using Conscia.Application.DTOs;
using FluentValidation;

namespace Conscia.Application.Validators;

public class UserProfileUpdateValidator : AbstractValidator<UserProfileUpdateDto>
{
    private static readonly HashSet<string> SupportedCurrencies =
        ["USD", "EUR", "GBP", "MXN", "CAD", "JPY", "AUD", "BRL", "INR"];

    public UserProfileUpdateValidator()
    {
        RuleFor(x => x.PreferredCurrency)
            .Length(3)
            .When(x => x.PreferredCurrency is not null)
            .WithMessage("Currency code must be a 3-letter ISO code");

        RuleFor(x => x.PreferredCurrency)
            .Must(c => c is null || SupportedCurrencies.Contains(c.ToUpperInvariant()))
            .WithMessage("Unsupported currency code");

        RuleFor(x => x.Locale)
            .MaximumLength(10)
            .When(x => x.Locale is not null);

        RuleFor(x => x)
            .Must(x => x.PreferredCurrency is not null || x.Locale is not null)
            .WithMessage("At least one field must be provided");
    }
}
