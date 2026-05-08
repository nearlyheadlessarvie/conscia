using Conscia.Application.DTOs;
using Conscia.Domain.Entities;

namespace Conscia.Application.Interfaces;

public interface IRecurringScheduleService
{
    Task<RecurringSchedule> CreateAsync(Guid userId, CreateRecurringScheduleDto dto, CancellationToken ct = default);
    Task<RecurringSchedule?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<RecurringSchedule>> ListAsync(Guid userId, CancellationToken ct = default);
    Task<RecurringSchedule> UpdateAsync(Guid userId, Guid id, UpdateRecurringScheduleDto dto, CancellationToken ct = default);
    Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default);
}
