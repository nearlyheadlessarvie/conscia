using Conscia.Application.DTOs;
using Conscia.Application.Models;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface ITransactionService
{
    Task<Transaction> CreateAsync(Guid userId, CreateTransactionDto dto, CancellationToken ct = default);
    Task<Transaction?> GetByIdAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task<PagedResult<Transaction>> ListAsync(Guid userId, int page, int pageSize, string? category = null, CancellationToken ct = default);
    Task<PagedResult<Transaction>> ListFamilyAsync(Guid userId, int page, int pageSize, string? category = null, CancellationToken ct = default);
    Task<Transaction> UpdateAsync(Guid userId, Guid id, UpdateTransactionDto dto, CancellationToken ct = default);
    Task DeleteAsync(Guid userId, Guid id, CancellationToken ct = default);
    Task UpdateRegretLevelAsync(Guid userId, Guid id, RegretLevel level, CancellationToken ct = default);
}
