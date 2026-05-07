using Conscia.Application.DTOs;
using FluentValidation;

namespace Conscia.Application.Validators;

public class UpdateTransactionValidator : AbstractValidator<UpdateTransactionDto>
{
    public UpdateTransactionValidator()
    {
        RuleFor(x => x.Amount)
            .GreaterThan(0)
            .When(x => x.Amount.HasValue)
            .WithMessage("Amount must be positive");

        RuleFor(x => x.CurrencyCode)
            .Length(3)
            .When(x => x.CurrencyCode is not null)
            .WithMessage("Currency code must be a 3-letter ISO code");

        RuleFor(x => x.Category)
            .MaximumLength(100)
            .When(x => x.Category is not null);

        RuleFor(x => x.Date)
            .LessThanOrEqualTo(_ => DateTime.UtcNow.AddDays(1))
            .When(x => x.Date.HasValue)
            .WithMessage("Date cannot be in the future");

        RuleFor(x => x)
            .Must(x => x.Type.HasValue || x.Amount.HasValue || x.CurrencyCode is not null
                || x.Category is not null || x.Counterparty is not null || x.Date.HasValue)
            .WithMessage("At least one field must be provided");
    }
}
