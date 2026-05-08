using Conscia.Application.DTOs;
using FluentValidation;

namespace Conscia.Application.Validators;

public class UpdateRecurringScheduleValidator : AbstractValidator<UpdateRecurringScheduleDto>
{
    public UpdateRecurringScheduleValidator()
    {
        RuleFor(x => x.Amount)
            .GreaterThan(0)
            .When(x => x.Amount.HasValue);

        RuleFor(x => x.CurrencyCode)
            .Length(3)
            .When(x => !string.IsNullOrWhiteSpace(x.CurrencyCode));

        RuleFor(x => x.Category)
            .MaximumLength(100)
            .When(x => !string.IsNullOrWhiteSpace(x.Category));

        RuleFor(x => x.EndDate)
            .Must((dto, endDate) => !dto.StartDate.HasValue || !endDate.HasValue || endDate.Value >= dto.StartDate.Value)
            .WithMessage("End date must be on or after start date");
    }
}
