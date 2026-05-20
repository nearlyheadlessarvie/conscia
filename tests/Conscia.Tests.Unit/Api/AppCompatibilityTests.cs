using System.Net;
using System.Net.Http.Headers;

namespace Conscia.Tests.Unit.Api;

public class AppCompatibilityTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public AppCompatibilityTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GetUsersMe_ReturnsUpgradeRequired_WhenAppVersionIsOlderThanPreviousSupported()
    {
        using var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Remove("X-Conscia-App-Version");
        using var request = new HttpRequestMessage(HttpMethod.Get, "/api/users/me?v=1");
        request.Headers.Add("X-Conscia-App-Version", "0.9.0+1");
        request.Headers.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken());

        var response = await client.SendAsync(request);

        Assert.Equal(HttpStatusCode.UpgradeRequired, response.StatusCode);
    }
}
