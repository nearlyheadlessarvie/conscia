using Conscia.Application.DTOs;
using FluentValidation;

namespace Conscia.Application.Validators;

public class CreateBudgetValidator : AbstractValidator<CreateBudgetDto>
{
    public CreateBudgetValidator()
    {
        RuleFor(x => x.Category)
            .NotEmpty()
            .MaximumLength(100);

        RuleFor(x => x.MonthlyLimit)
            .GreaterThan(0)
            .WithMessage("Monthly limit must be positive");

        RuleFor(x => x.CurrencyCode)
            .NotEmpty()
            .Length(3)
            .WithMessage("Currency code must be a 3-letter ISO code");
    }
}
