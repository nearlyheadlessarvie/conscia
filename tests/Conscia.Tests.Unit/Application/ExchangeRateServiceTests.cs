using System.Net;
using Conscia.Application.Interfaces;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Caching.Memory;
using Moq;
using Moq.Protected;

namespace Conscia.Tests.Unit.Application;

public class ExchangeRateServiceTests
{
    private static IExchangeRateService BuildService(HttpResponseMessage response)
    {
        var handler = new Mock<HttpMessageHandler>();
        handler.Protected()
            .Setup<Task<HttpResponseMessage>>("SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(response);

        var client = new HttpClient(handler.Object) { BaseAddress = new Uri("https://open.er-api.com") };
        var cache = new MemoryCache(new MemoryCacheOptions());
        return new ExchangeRateService(client, cache);
    }

    [Fact]
    public async Task GetRateAsync_ReturnsRate_WhenApiSucceeds()
    {
        var json = """{"result":"success","rates":{"USD":1.08,"GBP":0.86}}""";
        var svc = BuildService(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json")
        });

        var rate = await svc.GetRateAsync("EUR", "USD", default);

        Assert.NotNull(rate);
        Assert.Equal(1.08m, rate!.Value);
    }

    [Fact]
    public async Task GetRateAsync_ReturnsNull_WhenApiFails()
    {
        var svc = BuildService(new HttpResponseMessage(HttpStatusCode.ServiceUnavailable));

        var rate = await svc.GetRateAsync("EUR", "USD", default);

        Assert.Null(rate);
    }

    [Fact]
    public async Task GetRateAsync_ReturnsNull_WhenTargetCodeMissing()
    {
        var json = """{"result":"success","rates":{"USD":1.08}}""";
        var svc = BuildService(new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json")
        });

        var rate = await svc.GetRateAsync("EUR", "XYZ", default);

        Assert.Null(rate);
    }
}
