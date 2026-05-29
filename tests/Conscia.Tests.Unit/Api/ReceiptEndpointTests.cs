using System.Net;
using System.Net.Http.Headers;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class ReceiptEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public ReceiptEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Scan_UnsupportedContentType_Returns400()
    {
        using var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            _factory.GenerateTestToken());
        _factory.SubscriptionServiceMock
            .Setup(s => s.IsPremiumAsync(
                Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        using var form = new MultipartFormDataContent();
        using var image = new ByteArrayContent([1, 2, 3]);
        image.Headers.ContentType = new MediaTypeHeaderValue("image/heic");
        form.Add(image, "image", "receipt.heic");

        var response = await client.PostAsync("/api/receipts/scan", form);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
