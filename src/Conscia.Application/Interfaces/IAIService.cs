using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface IAIService
{
    Task<AIResponse> GeneratePrePurchaseResponseAsync(AIContext context, CancellationToken ct = default);
    Task<AIResponse> GenerateReflectionAsync(AIContext context, CancellationToken ct = default);
    Task<UtteranceParseResult> ParseUtteranceAsync(string transcript, CancellationToken ct = default);
}
