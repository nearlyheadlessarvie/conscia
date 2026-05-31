using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;

namespace Conscia.Tests.Unit.Api;

public class ClientDiagnosticEndpointTests
{
    [Fact]
    public async Task ReportClientDiagnostic_AuthenticatedRequest_ReturnsAccepted()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());

        var response = await client.PostAsJsonAsync("/api/client-diagnostics", new
        {
            eventName = "passkey.register.failed",
            level = "warning",
            operation = "register",
            platform = "ios",
            appVersion = "2.2.1+19",
            errorType = "PlatformException",
            errorCode = "failed",
            errorMessage = "The operation could not be completed.",
            context = new Dictionary<string, string>
            {
                ["rpId"] = "getconscia.com",
                ["excludeCredentialsCount"] = "0"
            }
        });

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
    }

    [Fact]
    public async Task ReportClientDiagnostic_MissingBearerToken_ReturnsUnauthorized()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/client-diagnostics", new
        {
            eventName = "passkey.register.failed"
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ReportClientDiagnostic_BlankEvent_ReturnsBadRequest()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());

        var response = await client.PostAsJsonAsync("/api/client-diagnostics", new
        {
            eventName = "",
            level = "warning"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }
}
