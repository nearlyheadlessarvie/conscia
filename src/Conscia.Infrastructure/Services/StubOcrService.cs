using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public class StubOcrService : IOcrService
{
    private readonly ILogger<StubOcrService> _logger;

    public bool IsConfigured => true;

    public StubOcrService(ILogger<StubOcrService> logger)
    {
        _logger = logger;
    }

    public Task<string> ExtractTextAsync(string s3Key, CancellationToken ct = default)
    {
        _logger.LogInformation("StubOcrService.ExtractTextAsync called for local receipt review. S3Key: {S3Key}", s3Key);
        return Task.FromResult("""
        Wildflour
        2026-05-21
        Brunch plate 1800.00
        Coffee 450.00
        Service charge 750.00
        TOTAL PHP 3000.00
        """);
    }

    public Task<ReceiptScanResultDto> ParseReceiptTextAsync(string rawText, CancellationToken ct = default)
    {
        _logger.LogInformation("StubOcrService.ParseReceiptTextAsync returned local demo receipt data");
        return Task.FromResult(new ReceiptScanResultDto
        {
            Merchant = "Wildflour",
            Total = 3000m,
            Date = DateTime.UtcNow,
            CurrencyCode = "PHP",
            Confidence = 0.72,
            LineItems =
            [
                new() { Description = "Brunch plate", Amount = 1800m, Quantity = 1 },
                new() { Description = "Coffee", Amount = 450m, Quantity = 1 },
                new() { Description = "Service charge", Amount = 750m, Quantity = 1 }
            ]
        });
    }
}
