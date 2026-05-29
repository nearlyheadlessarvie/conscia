using System.Text;
using Amazon.BedrockRuntime;
using Amazon.BedrockRuntime.Model;
using Amazon.Textract;
using Amazon.Textract.Model;
using Conscia.AI.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class AwsReceiptOcrServiceTests
{
    [Fact]
    public async Task ExtractTextAsync_ReadsReceiptTextFromConfiguredS3Object()
    {
        var textract = new Mock<IAmazonTextract>();
        var bedrock = new Mock<IAmazonBedrockRuntime>();
        DetectDocumentTextRequest? request = null;

        textract
            .Setup(t => t.DetectDocumentTextAsync(
                It.IsAny<DetectDocumentTextRequest>(),
                It.IsAny<CancellationToken>()))
            .Callback<DetectDocumentTextRequest, CancellationToken>((r, _) => request = r)
            .ReturnsAsync(new DetectDocumentTextResponse
            {
                Blocks =
                [
                    new Block { BlockType = BlockType.LINE, Text = "Corner Cafe" },
                    new Block { BlockType = BlockType.LINE, Text = "Total PHP 42.50" },
                    new Block { BlockType = BlockType.WORD, Text = "ignored-word" }
                ]
            });

        var service = CreateService(textract.Object, bedrock.Object);

        var text = await service.ExtractTextAsync("receipts/user/receipt.jpg");

        Assert.Equal("conscia-receipts", request?.Document.S3Object.Bucket);
        Assert.Equal("receipts/user/receipt.jpg", request?.Document.S3Object.Name);
        Assert.Contains("Corner Cafe", text);
        Assert.Contains("Total PHP 42.50", text);
        Assert.DoesNotContain("ignored-word", text);
    }

    [Fact]
    public async Task ExtractTextAsync_ThrowsArgumentException_WhenTextractRejectsDocumentFormat()
    {
        var textract = new Mock<IAmazonTextract>();
        var bedrock = new Mock<IAmazonBedrockRuntime>();
        textract
            .Setup(t => t.DetectDocumentTextAsync(
                It.IsAny<DetectDocumentTextRequest>(),
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new UnsupportedDocumentException("Request has unsupported document format"));

        var service = CreateService(textract.Object, bedrock.Object);

        var ex = await Assert.ThrowsAsync<ArgumentException>(() =>
            service.ExtractTextAsync("receipts/user/receipt.heic"));

        Assert.Equal("Receipt file format is not supported. Upload a JPEG, PNG, PDF, or TIFF receipt.", ex.Message);
    }

    [Fact]
    public async Task ParseReceiptTextAsync_ParsesBedrockJsonWithoutInventingCurrency()
    {
        var textract = new Mock<IAmazonTextract>();
        var bedrock = new Mock<IAmazonBedrockRuntime>();
        InvokeModelRequest? request = null;

        bedrock
            .Setup(b => b.InvokeModelAsync(
                It.IsAny<InvokeModelRequest>(),
                It.IsAny<CancellationToken>()))
            .Callback<InvokeModelRequest, CancellationToken>((r, _) => request = r)
            .ReturnsAsync(new InvokeModelResponse
            {
                Body = JsonBody("""
                {
                  "content": [
                    {
                      "text": "{\"merchant\":\"Corner Cafe\",\"total\":42.50,\"currencyCode\":null,\"date\":\"2026-05-21\",\"confidence\":0.81,\"lineItems\":[{\"description\":\"Latte\",\"amount\":42.50,\"quantity\":1}]}"
                    }
                  ]
                }
                """)
            });

        var service = CreateService(textract.Object, bedrock.Object);

        var result = await service.ParseReceiptTextAsync("Corner Cafe\nTotal 42.50");

        Assert.Equal("anthropic.claude-3-haiku-20240307-v1:0", request?.ModelId);
        Assert.Equal("application/json", request?.ContentType);
        Assert.Equal("application/json", request?.Accept);
        Assert.Equal("Corner Cafe", result.Merchant);
        Assert.Equal(42.50m, result.Total);
        Assert.Null(result.CurrencyCode);
        Assert.Equal(new DateTime(2026, 5, 21, 0, 0, 0, DateTimeKind.Utc), result.Date);
        Assert.Equal(0.81, result.Confidence, precision: 2);
        var item = Assert.Single(result.LineItems!);
        Assert.Equal("Latte", item.Description);
        Assert.Equal(42.50m, item.Amount);
        Assert.Equal(1, item.Quantity);
    }

    [Fact]
    public async Task ParseReceiptTextAsync_UsesDeterministicParse_WhenConfidenceIsHigh()
    {
        var textract = new Mock<IAmazonTextract>();
        var bedrock = new Mock<IAmazonBedrockRuntime>();
        var service = CreateService(textract.Object, bedrock.Object);

        var result = await service.ParseReceiptTextAsync("""
        Corner Cafe
        2026-05-21
        Latte 42.50
        TOTAL PHP 42.50
        """);

        Assert.Equal("Corner Cafe", result.Merchant);
        Assert.Equal(42.50m, result.Total);
        Assert.Equal("PHP", result.CurrencyCode);
        Assert.Equal(new DateTime(2026, 5, 21, 0, 0, 0, DateTimeKind.Utc), result.Date);
        Assert.True(result.Confidence >= 0.9);
        bedrock.Verify(b => b.InvokeModelAsync(
            It.IsAny<InvokeModelRequest>(),
            It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task ParseReceiptTextAsync_FallsBackToBedrock_WhenDeterministicParseIsLowConfidence()
    {
        var textract = new Mock<IAmazonTextract>();
        var bedrock = new Mock<IAmazonBedrockRuntime>();

        bedrock
            .Setup(b => b.InvokeModelAsync(
                It.IsAny<InvokeModelRequest>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new InvokeModelResponse
            {
                Body = JsonBody("""
                {
                  "content": [
                    {
                      "text": "{\"merchant\":\"Blurred Store\",\"total\":99.00,\"currencyCode\":\"PHP\",\"date\":null,\"confidence\":0.72,\"lineItems\":[]}"
                    }
                  ]
                }
                """)
            });

        var service = CreateService(textract.Object, bedrock.Object);

        var result = await service.ParseReceiptTextAsync("Blurred Store\nAmount maybe 99");

        Assert.Equal("Blurred Store", result.Merchant);
        Assert.Equal(99.00m, result.Total);
        Assert.Equal("PHP", result.CurrencyCode);
        bedrock.Verify(b => b.InvokeModelAsync(
            It.IsAny<InvokeModelRequest>(),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    private static AwsReceiptOcrService CreateService(
        IAmazonTextract textract,
        IAmazonBedrockRuntime bedrock)
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["AWS:S3:BucketName"] = "conscia-receipts"
            })
            .Build();

        return new AwsReceiptOcrService(
            textract,
            bedrock,
            configuration,
            Options.Create(new BedrockOptions()),
            NullLogger<AwsReceiptOcrService>.Instance);
    }

    private static MemoryStream JsonBody(string json) =>
        new(Encoding.UTF8.GetBytes(json));
}
