using Amazon.Lambda;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;

namespace Conscia.Infrastructure.Db.LambdaProxy;

public class LambdaProxyReceiptRepository : LambdaProxyRepository, IReceiptRepository
{
    public LambdaProxyReceiptRepository(IAmazonLambda lambda, string functionName)
        : base(lambda, functionName) { }

    public Task<Receipt?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        InvokeAsync<Receipt?>("Receipt.GetById", new { Id = id }, ct);

    public Task<Receipt?> GetByTransactionIdAsync(Guid transactionId, CancellationToken ct = default) =>
        InvokeAsync<Receipt?>("Receipt.GetByTransactionId", new { TransactionId = transactionId }, ct);

    public Task<Receipt> AddAsync(Receipt receipt, CancellationToken ct = default) =>
        InvokeAsync<Receipt>("Receipt.Add", receipt, ct);

    public Task<Receipt> UpdateAsync(Receipt receipt, CancellationToken ct = default) =>
        InvokeAsync<Receipt>("Receipt.Update", receipt, ct);

    public async Task UpdateStatusAsync(Guid id, ReceiptStatus status, CancellationToken ct = default) =>
        await InvokeAsync<object>("Receipt.UpdateStatus", new { Id = id, Status = status.ToString() }, ct);
}
