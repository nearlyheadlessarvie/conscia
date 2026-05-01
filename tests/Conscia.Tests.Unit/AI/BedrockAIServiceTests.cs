using System.Text;
using System.Text.Json;
using Amazon.BedrockRuntime;
using Amazon.BedrockRuntime.Model;
using Conscia.AI.Services;
using Conscia.Application.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;

namespace Conscia.Tests.Unit.AI;

public class BedrockAIServiceTests
{
    private readonly Mock<IAmazonBedrockRuntime> _bedrockMock = new();

    private static AIContext CreateTestContext() => new()
    {
        UserId = Guid.NewGuid(),
        Amount = 29.99m,
        CurrencyCode = "EUR",
        Category = "Entertainment",
        BudgetPercentUsed = 45m,
        RecentRegrets = 1,
        SpendingFrequencyThisWeek = 3
    };

    private void SetupBedrockReturns(string text)
    {
        _bedrockMock
            .Setup(b => b.InvokeModelAsync(It.IsAny<InvokeModelRequest>(), It.IsAny<CancellationToken>()))
            .Returns(() => Task.FromResult(CreateBedrockResponse(text)));
    }

    private BedrockAIService CreateService()
    {
        var options = Options.Create(new BedrockOptions
        {
            ModelId = "anthropic.claude-3-haiku-20240307-v1:0",
            MaxTokens = 200
        });

        return new BedrockAIService(_bedrockMock.Object, options, Mock.Of<ILogger<BedrockAIService>>());
    }

    private static InvokeModelResponse CreateBedrockResponse(string text)
    {
        var responseBody = JsonSerializer.Serialize(new
        {
            content = new[] { new { type = "text", text } }
        });

        return new InvokeModelResponse
        {
            Body = new MemoryStream(Encoding.UTF8.GetBytes(responseBody)),
            ContentType = "application/json"
        };
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_ReturnsThreeResponses()
    {
        SetupBedrockReturns("Bedrock says hello");

        var service = CreateService();
        var result = await service.GeneratePrePurchaseResponseAsync(CreateTestContext());

        Assert.Equal("Bedrock says hello", result.DevilMessage);
        Assert.Equal("Bedrock says hello", result.AngelMessage);
        Assert.NotEmpty(result.NeutralMessage);
    }

    [Fact]
    public async Task GenerateReflectionAsync_ReturnsThreeResponses()
    {
        SetupBedrockReturns("Reflection from Claude");

        var service = CreateService();
        var result = await service.GenerateReflectionAsync(CreateTestContext());

        Assert.Equal("Reflection from Claude", result.DevilMessage);
        Assert.Equal("Reflection from Claude", result.AngelMessage);
        Assert.NotEmpty(result.NeutralMessage);
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_MakesTwoParallelCalls()
    {
        SetupBedrockReturns("ok");

        var service = CreateService();
        await service.GeneratePrePurchaseResponseAsync(CreateTestContext());

        _bedrockMock.Verify(
            b => b.InvokeModelAsync(It.IsAny<InvokeModelRequest>(), It.IsAny<CancellationToken>()),
            Times.Exactly(2));
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_BedrockError_ReturnsFallbackMessages()
    {
        _bedrockMock
            .Setup(b => b.InvokeModelAsync(It.IsAny<InvokeModelRequest>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new AmazonBedrockRuntimeException("Model throttled"));

        var service = CreateService();
        var result = await service.GeneratePrePurchaseResponseAsync(CreateTestContext());

        Assert.NotEmpty(result.DevilMessage);
        Assert.NotEmpty(result.AngelMessage);
        Assert.NotEmpty(result.NeutralMessage);
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_SendsCorrectModelId()
    {
        InvokeModelRequest? capturedRequest = null;
        _bedrockMock
            .Setup(b => b.InvokeModelAsync(It.IsAny<InvokeModelRequest>(), It.IsAny<CancellationToken>()))
            .Callback<InvokeModelRequest, CancellationToken>((req, _) => capturedRequest = req)
            .Returns(() => Task.FromResult(CreateBedrockResponse("ok")));

        var service = CreateService();
        await service.GeneratePrePurchaseResponseAsync(CreateTestContext());

        Assert.NotNull(capturedRequest);
        Assert.Equal("anthropic.claude-3-haiku-20240307-v1:0", capturedRequest.ModelId);
    }

    [Fact]
    public async Task GeneratePrePurchaseResponseAsync_SendsAnthropicVersionInPayload()
    {
        byte[]? capturedBody = null;
        _bedrockMock
            .Setup(b => b.InvokeModelAsync(It.IsAny<InvokeModelRequest>(), It.IsAny<CancellationToken>()))
            .Callback<InvokeModelRequest, CancellationToken>((req, _) =>
            {
                req.Body.Position = 0;
                using var ms = new MemoryStream();
                req.Body.CopyTo(ms);
                capturedBody = ms.ToArray();
            })
            .Returns(() => Task.FromResult(CreateBedrockResponse("ok")));

        var service = CreateService();
        await service.GeneratePrePurchaseResponseAsync(CreateTestContext());

        Assert.NotNull(capturedBody);
        using var doc = JsonDocument.Parse(capturedBody);

        Assert.Equal("bedrock-2023-05-31", doc.RootElement.GetProperty("anthropic_version").GetString());
        Assert.Equal(200, doc.RootElement.GetProperty("max_tokens").GetInt32());
    }
}
