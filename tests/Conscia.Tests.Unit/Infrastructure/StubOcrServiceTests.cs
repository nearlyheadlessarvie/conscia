using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Logging.Abstractions;

namespace Conscia.Tests.Unit.Infrastructure;

public class StubOcrServiceTests
{
    [Fact]
    public async Task ParseReceiptTextAsync_ReturnsReviewableLocalDemoReceipt()
    {
        var service = new StubOcrService(NullLogger<StubOcrService>.Instance);

        var result = await service.ParseReceiptTextAsync("ignored local text");

        Assert.True(service.IsConfigured);
        Assert.Equal("Wildflour", result.Merchant);
        Assert.Equal(3000m, result.Total);
        Assert.Equal("PHP", result.CurrencyCode);
        Assert.True(result.Confidence > 0);
        Assert.NotEmpty(result.LineItems!);
    }
}
