using Conscia.Application.DTOs;
using FluentValidation;

namespace Conscia.Application.Validators;

public class CreateRecurringScheduleValidator : AbstractValidator<CreateRecurringScheduleDto>
{
    public CreateRecurringScheduleValidator()
    {
        RuleFor(x => x.Amount).GreaterThan(0);
        RuleFor(x => x.CurrencyCode).NotEmpty().Length(3);
        RuleFor(x => x.Category).NotEmpty().MaximumLength(100);
        RuleFor(x => x.StartDate).NotEmpty();
        RuleFor(x => x.EndDate)
            .Must((dto, endDate) => !endDate.HasValue || endDate.Value >= dto.StartDate)
            .WithMessage("End date must be on or after start date");
    }
}
