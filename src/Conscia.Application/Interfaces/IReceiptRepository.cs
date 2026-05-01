using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Application.Interfaces;

public interface IReceiptRepository
{
    Task<Receipt?> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<Receipt?> GetByTransactionIdAsync(Guid transactionId, CancellationToken ct = default);
    Task<Receipt> AddAsync(Receipt receipt, CancellationToken ct = default);
    Task<Receipt> UpdateAsync(Receipt receipt, CancellationToken ct = default);
    Task UpdateStatusAsync(Guid id, ReceiptStatus status, CancellationToken ct = default);
}
