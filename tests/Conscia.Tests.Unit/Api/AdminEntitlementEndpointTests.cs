using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.DTOs;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class AdminEntitlementEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly TestWebAppFactory _factory;

    public AdminEntitlementEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task GrantLifetimePremium_Returns403_ForNonAdminCaller()
    {
        _factory.AdminAuthorizationServiceMock
            .Setup(s => s.IsAuthorizedAsync(
                It.IsAny<Guid>(),
                It.IsAny<string>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken(tier: "Premium"));

        var response = await client.PutAsJsonAsync(
            "/api/admin/entitlements/premium-lifetime/a1b2c3d4-0001-4000-8000-000000000001",
            new { grantedBy = "spec-test", note = "founder comp" });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task LookupByEmail_Returns200_ForAuthorizedCaller()
    {
        _factory.AdminAuthorizationServiceMock
            .Setup(s => s.IsAuthorizedAsync(
                It.IsAny<Guid>(),
                It.IsAny<string>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _factory.SubscriptionAdminServiceMock
            .Setup(s => s.LookupByEmailAsync("founder@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AdminUserLookupResponse(
                Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001"),
                "founder@example.com",
                true,
                "lifetime",
                true));

        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken(email: "admin@example.com"));

        var response = await client.GetAsync("/api/admin/users/by-email?email=founder@example.com");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("founder@example.com", body);
        Assert.Contains("lifetime", body);
    }

    [Fact]
    public async Task Access_Returns200_ForAuthorizedCaller()
    {
        _factory.AdminAuthorizationServiceMock
            .Setup(s => s.IsAuthorizedAsync(
                It.IsAny<Guid>(),
                It.IsAny<string>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var client = _factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _factory.GenerateTestToken(email: "admin@example.com"));

        var response = await client.GetAsync("/api/admin/access");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"isAdmin\":true", body);
    }
}
