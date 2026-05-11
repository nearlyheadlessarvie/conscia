using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Conscia.Application.DTOs;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class FamilySpaceEndpointTests
{
    private static readonly Guid UserId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");

    [Fact]
    public async Task CreateFamilySpace_ValidRequest_ReturnsCreated()
    {
        await using var factory = new TestWebAppFactory();
        var familySpaceId = Guid.Parse("aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa");
        factory.FamilySpaceServiceMock
            .Setup(s => s.CreateAsync(UserId, "Santos Household", "PHP", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilySpace
            {
                Id = familySpaceId,
                Name = "Santos Household",
                CurrencyCode = "PHP",
                CreatedByUserId = UserId
            });

        var client = CreateAuthorizedClient(factory);
        var response = await client.PostAsJsonAsync("/api/v1/family-space", new
        {
            name = "Santos Household",
            currencyCode = "PHP"
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.Equal($"/api/v1/family-space/{familySpaceId}", response.Headers.Location?.ToString());

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Santos Household", json.GetProperty("name").GetString());
        Assert.Equal("PHP", json.GetProperty("currencyCode").GetString());
    }

    [Fact]
    public async Task CreateFamilySpace_FreeUser_ReturnsForbiddenUpgradeRequired()
    {
        await using var factory = new TestWebAppFactory();
        factory.FamilySpaceServiceMock
            .Setup(s => s.CreateAsync(It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new InvalidOperationException("Family Space requires Premium."));

        var client = CreateAuthorizedClient(factory, tier: "Free");
        var response = await client.PostAsJsonAsync("/api/v1/family-space", new
        {
            name = "Santos Household",
            currencyCode = "PHP"
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(json.GetProperty("upgradeRequired").GetBoolean());
    }

    [Fact]
    public async Task GetFamilySpace_WhenMember_ReturnsCurrentSpace()
    {
        await using var factory = new TestWebAppFactory();
        factory.FamilySpaceServiceMock
            .Setup(s => s.GetCurrentAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilySpaceDto(
                Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"),
                "Santos Household",
                "PHP",
                false,
                FamilyMemberRole.Owner.ToString()));

        var client = CreateAuthorizedClient(factory);
        var response = await client.GetAsync("/api/v1/family-space");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Santos Household", json.GetProperty("name").GetString());
        Assert.Equal("Owner", json.GetProperty("role").GetString());
    }

    [Fact]
    public async Task GetFamilySpace_WhenNotMember_ReturnsNoContent()
    {
        await using var factory = new TestWebAppFactory();
        factory.FamilySpaceServiceMock
            .Setup(s => s.GetCurrentAsync(UserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilySpaceDto?)null);

        var client = CreateAuthorizedClient(factory);
        var response = await client.GetAsync("/api/v1/family-space");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    [Fact]
    public async Task CreateInvite_OwnerRequest_ReturnsCreatedInvite()
    {
        await using var factory = new TestWebAppFactory();
        var inviteId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");
        factory.FamilySpaceServiceMock
            .Setup(s => s.InviteAsync(UserId, "wife@example.com", FamilyMemberRole.Contributor, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyInvite
            {
                Id = inviteId,
                FamilySpaceId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"),
                Email = "wife@example.com",
                Role = FamilyMemberRole.Contributor,
                ExpiresAt = DateTime.UtcNow.AddDays(14)
            });

        var client = CreateAuthorizedClient(factory);
        var response = await client.PostAsJsonAsync("/api/v1/family-space/invites", new
        {
            email = "wife@example.com",
            role = "Contributor"
        });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        Assert.Equal($"/api/v1/family-space/invites/{inviteId}", response.Headers.Location?.ToString());

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("wife@example.com", json.GetProperty("email").GetString());
        Assert.Equal("Contributor", json.GetProperty("role").GetString());
    }

    [Fact]
    public async Task CreateInvite_ContributorRequest_ReturnsForbidden()
    {
        await using var factory = new TestWebAppFactory();
        factory.FamilySpaceServiceMock
            .Setup(s => s.InviteAsync(It.IsAny<Guid>(), It.IsAny<string>(), It.IsAny<FamilyMemberRole>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new UnauthorizedAccessException("Only Family Space owners can invite members."));

        var client = CreateAuthorizedClient(factory);
        var response = await client.PostAsJsonAsync("/api/v1/family-space/invites", new
        {
            email = "wife@example.com",
            role = "Contributor"
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    private static HttpClient CreateAuthorizedClient(
        TestWebAppFactory factory,
        string tier = "Premium")
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken(UserId.ToString(), tier: tier));
        return client;
    }
}
