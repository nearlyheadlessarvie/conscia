namespace Conscia.Application.Interfaces;

public interface IReceiptService
{
    Task<ReceiptScanResult> ScanAsync(Guid userId, Stream imageStream, CancellationToken ct = default);
    Task<object> ConfirmAsync(Guid userId, Guid receiptId, CancellationToken ct = default);
}
