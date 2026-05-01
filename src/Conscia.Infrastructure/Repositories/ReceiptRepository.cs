using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Infrastructure.Repositories;

public class ReceiptRepository : IReceiptRepository
{
    private readonly ConsciaDbContext _db;

    public ReceiptRepository(ConsciaDbContext db) => _db = db;

    public async Task<Receipt?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await _db.Receipts.FindAsync([id], ct);

    public async Task<Receipt?> GetByTransactionIdAsync(Guid transactionId, CancellationToken ct = default) =>
        await _db.Receipts.FirstOrDefaultAsync(r => r.TransactionId == transactionId, ct);

    public async Task<Receipt> AddAsync(Receipt receipt, CancellationToken ct = default)
    {
        _db.Receipts.Add(receipt);
        await _db.SaveChangesAsync(ct);
        return receipt;
    }

    public async Task<Receipt> UpdateAsync(Receipt receipt, CancellationToken ct = default)
    {
        _db.Receipts.Update(receipt);
        await _db.SaveChangesAsync(ct);
        return receipt;
    }

    public async Task UpdateStatusAsync(Guid id, ReceiptStatus status, CancellationToken ct = default)
    {
        await _db.Receipts
            .Where(r => r.Id == id)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(r => r.Status, status), ct);
    }
}
