using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Infrastructure.Repositories;

public class BudgetRepository : IBudgetRepository
{
    private readonly ConsciaDbContext _db;

    public BudgetRepository(ConsciaDbContext db) => _db = db;

    public async Task<Budget?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        await _db.Budgets.FindAsync([id], ct);

    public async Task<IReadOnlyList<Budget>> ListByUserAsync(Guid userId, CancellationToken ct = default) =>
        await _db.Budgets.Where(b => b.UserId == userId).ToListAsync(ct);

    public async Task<Budget> AddAsync(Budget budget, CancellationToken ct = default)
    {
        _db.Budgets.Add(budget);
        await _db.SaveChangesAsync(ct);
        return budget;
    }

    public async Task<Budget> UpdateAsync(Budget budget, CancellationToken ct = default)
    {
        _db.Budgets.Update(budget);
        await _db.SaveChangesAsync(ct);
        return budget;
    }

    public async Task DeleteAsync(Guid id, CancellationToken ct = default)
    {
        var budget = await _db.Budgets.FindAsync([id], ct);
        if (budget is not null)
        {
            _db.Budgets.Remove(budget);
            await _db.SaveChangesAsync(ct);
        }
    }

    public async Task IncrementCurrentSpendAsync(Guid id, decimal delta, CancellationToken ct = default)
    {
        await _db.Budgets
            .Where(b => b.Id == id)
            .ExecuteUpdateAsync(s =>
                s.SetProperty(b => b.CurrentSpend, b => b.CurrentSpend + delta), ct);
    }
}
