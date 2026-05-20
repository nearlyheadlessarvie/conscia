using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public class StubOcrService : IOcrService
{
    private readonly ILogger<StubOcrService> _logger;

    public bool IsConfigured => false;

    public StubOcrService(ILogger<StubOcrService> logger)
    {
        _logger = logger;
    }

    public Task<string> ExtractTextAsync(string s3Key, CancellationToken ct = default)
    {
        _logger.LogWarning("StubOcrService.ExtractTextAsync called — Textract not configured. S3Key: {S3Key}", s3Key);
        return Task.FromResult("STUB: No OCR text extracted. Configure Textract for production.");
    }

    public Task<ReceiptScanResultDto> ParseReceiptTextAsync(string rawText, CancellationToken ct = default)
    {
        _logger.LogWarning("StubOcrService.ParseReceiptTextAsync called — Bedrock parsing not configured");
        return Task.FromResult(new ReceiptScanResultDto
        {
            Merchant = "Unknown Merchant",
            Total = 0m,
            Date = DateTime.UtcNow,
            CurrencyCode = "USD",
            Confidence = 0.0,
            LineItems = new List<LineItemDto>()
        });
    }
}
