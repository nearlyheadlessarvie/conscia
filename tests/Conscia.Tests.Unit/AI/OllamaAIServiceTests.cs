using System.Net;
using System.Text.Json;
using Conscia.AI.Services;
using Conscia.Application.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;

namespace Conscia.Tests.Unit.AI;

public class OllamaAIServiceTests
{
    private static AIContext CreateTestContext() => new()
    {
        UserId = Guid.NewGuid(),
        Amount = 49.99m,
        CurrencyCode = "USD",
        Category = "Food",
        BudgetPercentUsed = 70m,
        RecentRegrets = 2,
        SpendingFrequencyThisWeek = 4
    };

    private static OllamaAIService CreateService(HttpClient httpClient)
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Ollama:Model"] = "llama3.2"
            })
            .Build();

        return new OllamaAIService(httpClient, config, Mock.Of<ILogger<OllamaAIService>>());
    }

    private static HttpClient CreateMockHttpClient(Func<HttpRequestMessage, Task<HttpResponseMessage>> handler)
    {
        var mockHandler = new MockHttpMessageHandler(handler);
        return new HttpClient(mockHandler) { BaseAddress = new Uri("http://localhost:11434") };
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_ReturnsThreeResponses()
    {
        var httpClient = CreateMockHttpClient(_ =>
        {
            var json = JsonSerializer.Serialize(new { message = new { role = "assistant", content = "Test response" } });
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json")
            });
        });

        var service = CreateService(httpClient);
        var result = await service.GeneratePrePurchaseResponseAsync(CreateTestContext());

        Assert.Equal("Test response", result.DevilMessage);
        Assert.Equal("Test response", result.AngelMessage);
        Assert.NotEmpty(result.NeutralMessage);
    }

    [Fact]
    public async Task GenerateReflectionAsync_ReturnsThreeResponses()
    {
        var httpClient = CreateMockHttpClient(_ =>
        {
            var json = JsonSerializer.Serialize(new { message = new { role = "assistant", content = "Reflection response" } });
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json")
            });
        });

        var service = CreateService(httpClient);
        var result = await service.GenerateReflectionAsync(CreateTestContext());

        Assert.Equal("Reflection response", result.DevilMessage);
        Assert.Equal("Reflection response", result.AngelMessage);
        Assert.NotEmpty(result.NeutralMessage);
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_MakesTwoParallelCalls()
    {
        var callCount = 0;
        var httpClient = CreateMockHttpClient(_ =>
        {
            Interlocked.Increment(ref callCount);
            var json = JsonSerializer.Serialize(new { message = new { role = "assistant", content = "ok" } });
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json")
            });
        });

        var service = CreateService(httpClient);
        await service.GeneratePrePurchaseResponseAsync(CreateTestContext());

        Assert.Equal(3, callCount);
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_IntenseProfile_UsesHigherImpulseTemperature()
    {
        var temperatures = new List<float>();
        var httpClient = CreateMockHttpClient(async request =>
        {
            var payloadJson = await request.Content!.ReadAsStringAsync();
            var payload = JsonSerializer.Deserialize<JsonElement>(payloadJson);
            temperatures.Add(payload.GetProperty("options").GetProperty("temperature").GetSingle());

            var json = JsonSerializer.Serialize(new { message = new { role = "assistant", content = "ok" } });
            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(json, System.Text.Encoding.UTF8, "application/json")
            };
        });

        var service = CreateService(httpClient);
        var context = CreateTestContext();
        context.AiPersonalityIntensity = "intense";

        await service.GeneratePrePurchaseResponseAsync(context);

        Assert.Contains(1.0f, temperatures);
        Assert.Contains(0.42f, temperatures);
        Assert.Contains(0.5f, temperatures);
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_OllamaDown_ReturnsFallbackMessages()
    {
        var httpClient = CreateMockHttpClient(_ =>
            Task.FromResult(new HttpResponseMessage(HttpStatusCode.InternalServerError)));

        var service = CreateService(httpClient);
        var result = await service.GeneratePrePurchaseResponseAsync(CreateTestContext());

        Assert.NotEmpty(result.DevilMessage);
        Assert.NotEmpty(result.AngelMessage);
        Assert.NotEmpty(result.NeutralMessage);
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_RequestTimeout_ReturnsFallbackMessages()
    {
        var httpClient = CreateMockHttpClient(_ =>
            throw new TaskCanceledException("Request timed out"));

        var service = CreateService(httpClient);
        var result = await service.GeneratePrePurchaseResponseAsync(CreateTestContext());

        Assert.NotEmpty(result.DevilMessage);
        Assert.NotEmpty(result.AngelMessage);
        Assert.NotEmpty(result.NeutralMessage);
    }

    private class MockHttpMessageHandler(Func<HttpRequestMessage, Task<HttpResponseMessage>> handler) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken)
            => handler(request);
    }
}
