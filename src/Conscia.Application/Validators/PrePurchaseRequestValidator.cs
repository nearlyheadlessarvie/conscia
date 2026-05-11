using Conscia.Application.DTOs;
using FluentValidation;

namespace Conscia.Application.Validators;

public class PrePurchaseRequestValidator : AbstractValidator<PrePurchaseRequestDto>
{
    public PrePurchaseRequestValidator()
    {
        RuleFor(x => x.Description)
            .NotEmpty()
            .MaximumLength(500);

        RuleFor(x => x.Amount)
            .GreaterThan(0)
            .WithMessage("Amount must be positive");

        RuleFor(x => x.CurrencyCode)
            .NotEmpty()
            .Length(3)
            .WithMessage("Currency code must be a 3-letter ISO code");

        RuleFor(x => x.Category)
            .NotEmpty()
            .MaximumLength(100);

        RuleFor(x => x.ContextScope)
            .Must(scope =>
                string.Equals(scope, "personal", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(scope, "family", StringComparison.OrdinalIgnoreCase))
            .WithMessage("Context scope must be personal or family");
    }
}
