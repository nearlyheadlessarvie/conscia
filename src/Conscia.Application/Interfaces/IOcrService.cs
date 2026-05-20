using Conscia.Application.DTOs;

namespace Conscia.Application.Interfaces;

public interface IOcrService
{
    bool IsConfigured { get; }
    Task<string> ExtractTextAsync(string s3Key, CancellationToken ct = default);
    Task<ReceiptScanResultDto> ParseReceiptTextAsync(string rawText, CancellationToken ct = default);
}
