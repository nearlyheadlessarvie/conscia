using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface IPurchaseSuggestionService
{
    Task<IReadOnlyList<PurchaseSuggestionDto>> GetSuggestionsAsync(Guid userId, CancellationToken ct = default);
}
