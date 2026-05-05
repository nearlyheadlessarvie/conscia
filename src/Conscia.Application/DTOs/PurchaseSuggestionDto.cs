namespace Conscia.Application.DTOs;

public record PurchaseSuggestionDto(
    string Description,
    decimal Amount,
    string CurrencyCode,
    string Category,
    string FrequencyLabel
);
