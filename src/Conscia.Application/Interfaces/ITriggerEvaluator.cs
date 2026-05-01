using Conscia.Application.Models;

namespace Conscia.Application.Interfaces;

public interface ITriggerEvaluator
{
    string TriggerName { get; }
    Task<IReadOnlyList<InAppAlert>> EvaluateAsync(Guid userId, CancellationToken ct = default);
}
