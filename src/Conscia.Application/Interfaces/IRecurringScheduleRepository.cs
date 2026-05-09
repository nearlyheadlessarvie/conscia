using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IRecurringScheduleRepository
{
    Task<RecurringSchedule> AddAsync(RecurringSchedule schedule, CancellationToken ct = default);
    Task<RecurringSchedule?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<RecurringSchedule>> ListAsync(Guid userId, CancellationToken ct = default);
    Task UpdateAsync(RecurringSchedule schedule, CancellationToken ct = default);
    Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<RecurringSchedule>> ListDueAsync(DateTime nowUtc, CancellationToken ct = default);
}
