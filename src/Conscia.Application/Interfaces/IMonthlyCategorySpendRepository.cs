using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IMonthlyCategorySpendRepository
{
    Task UpsertAsync(MonthlyCategorySpend projection, CancellationToken ct = default);

    Task<IReadOnlyList<MonthlyCategorySpend>> ListRecentMonthsAsync(
        Guid userId,
        IReadOnlyList<string> monthKeys,
        CancellationToken ct = default);

    Task<IReadOnlyList<MonthlyCategorySpend>> ListByUserAsync(Guid userId, CancellationToken ct = default);
}
