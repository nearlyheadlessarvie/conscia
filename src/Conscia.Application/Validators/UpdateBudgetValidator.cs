using Conscia.Application.DTOs;
using FluentValidation;

namespace Conscia.Application.Validators;

public class UpdateBudgetValidator : AbstractValidator<UpdateBudgetDto>
{
    public UpdateBudgetValidator()
    {
        RuleFor(x => x.MonthlyLimit)
            .GreaterThan(0)
            .When(x => x.MonthlyLimit.HasValue)
            .WithMessage("Monthly limit must be positive");

        RuleFor(x => x.Category)
            .MaximumLength(100)
            .When(x => x.Category is not null);

        RuleFor(x => x)
            .Must(x => x.MonthlyLimit.HasValue || x.Category is not null)
            .WithMessage("At least one field must be provided");
    }
}
