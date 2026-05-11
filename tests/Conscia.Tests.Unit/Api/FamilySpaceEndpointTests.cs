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

    [Fact]
    public async Task ListInvites_ReturnsPendingInvitesForSignedInEmail()
    {
        await using var factory = new TestWebAppFactory();
        var inviteId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");
        factory.FamilySpaceServiceMock
            .Setup(s => s.GetPendingInvitesAsync("alice@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new FamilyInviteDto(
                    inviteId,
                    Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"),
                    "Santos Household",
                    "alice@example.com",
                    "Contributor",
                    DateTime.UtcNow.AddDays(-1),
                    DateTime.UtcNow.AddDays(13))
            ]);

        var client = CreateAuthorizedClient(factory, email: "alice@example.com");
        var response = await client.GetAsync("/api/v1/family-space/invites");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        var invite = Assert.Single(json.EnumerateArray());
        Assert.Equal(inviteId, invite.GetProperty("id").GetGuid());
        Assert.Equal("Santos Household", invite.GetProperty("familySpaceName").GetString());
        Assert.Equal("Contributor", invite.GetProperty("role").GetString());
    }

    [Fact]
    public async Task AcceptInvite_UsesSignedInEmailAndReturnsAcceptedMember()
    {
        await using var factory = new TestWebAppFactory();
        var inviteId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");
        var familySpaceId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
        factory.FamilySpaceServiceMock
            .Setup(s => s.AcceptInviteAsync(UserId, "alice@example.com", inviteId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                Id = Guid.Parse("eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee"),
                FamilySpaceId = familySpaceId,
                UserId = UserId,
                Role = FamilyMemberRole.Contributor,
                JoinedAt = DateTime.UtcNow
            });

        var client = CreateAuthorizedClient(factory, email: "alice@example.com");
        var response = await client.PostAsync($"/api/v1/family-space/invites/{inviteId}/accept", null);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(familySpaceId, json.GetProperty("familySpaceId").GetGuid());
        Assert.Equal("Contributor", json.GetProperty("role").GetString());
    }

    [Fact]
    public async Task DeclineInvite_UsesSignedInEmailAndReturnsNoContent()
    {
        await using var factory = new TestWebAppFactory();
        var inviteId = Guid.Parse("cccccccc-cccc-cccc-cccc-cccccccccccc");
        factory.FamilySpaceServiceMock
            .Setup(s => s.DeclineInviteAsync(UserId, "alice@example.com", inviteId, It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        var client = CreateAuthorizedClient(factory, email: "alice@example.com");
        var response = await client.PostAsync($"/api/v1/family-space/invites/{inviteId}/decline", null);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        factory.FamilySpaceServiceMock.Verify(s =>
            s.DeclineInviteAsync(UserId, "alice@example.com", inviteId, It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task PreviewImport_ContributorRequest_ReturnsPreview()
    {
        await using var factory = new TestWebAppFactory();
        var familySpaceId = Guid.Parse("bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb");
        var transactionId = Guid.Parse("dddddddd-dddd-dddd-dddd-dddddddddddd");
        factory.FamilySpaceServiceMock
            .Setup(s => s.PreviewImportAsync(UserId, It.IsAny<FamilyImportPreviewRequestDto>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyImportPreviewDto(
                familySpaceId,
                "These records will become visible to your Family Space.",
                [
                    new FamilyImportItemDto("transaction", transactionId, "Starbucks", "Dining", 280m, "PHP")
                ]));

        var client = CreateAuthorizedClient(factory);
        var response = await client.PostAsJsonAsync("/api/v1/family-space/import-preview", new
        {
            includeTransactions = true,
            includeBudgets = false,
            includeRecurringSchedules = false,
            from = "2026-05-01T00:00:00Z",
            to = "2026-05-31T23:59:59Z",
            categories = new[] { "Dining" }
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(familySpaceId, json.GetProperty("familySpaceId").GetGuid());
        Assert.Single(json.GetProperty("items").EnumerateArray());
    }

    [Fact]
    public async Task ImportRecords_ViewerRequest_ReturnsForbidden()
    {
        await using var factory = new TestWebAppFactory();
        factory.FamilySpaceServiceMock
            .Setup(s => s.ImportAsync(UserId, It.IsAny<FamilyImportRequestDto>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new UnauthorizedAccessException("Viewer cannot share records."));

        var client = CreateAuthorizedClient(factory);
        var response = await client.PostAsJsonAsync("/api/v1/family-space/import", new
        {
            items = new[]
            {
                new
                {
                    recordType = "transaction",
                    recordId = Guid.Parse("dddddddd-dddd-dddd-dddd-dddddddddddd")
                }
            }
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    private static HttpClient CreateAuthorizedClient(
        TestWebAppFactory factory,
        string tier = "Premium",
        string email = "alice@example.com")
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken(UserId.ToString(), email: email, tier: tier));
        return client;
    }
}
