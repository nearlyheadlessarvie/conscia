using System.Net;
using System.Net.Http.Headers;

namespace Conscia.Tests.Unit.Api;

public class ApiVersioningTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public ApiVersioningTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task ApiRoot_ReturnsOk_WhenVersionIsProvidedByQuery()
    {
        using var client = _factory.CreateRawClient();

        var response = await client.GetAsync("/api?v=1");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task ApiRoot_ReturnsBadRequest_WhenVersionIsMissing()
    {
        using var client = _factory.CreateRawClient();

        var response = await client.GetAsync("/api");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task ApiRoot_ReturnsOk_WhenVersionIsProvidedByHeader()
    {
        using var client = _factory.CreateRawClient();
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api");
        request.Headers.Add("X-Api-Version", "1");

        var response = await client.SendAsync(request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
