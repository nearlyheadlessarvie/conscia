using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Text.Json;
using Amazon.S3;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class UserEndpointTests : IClassFixture<TestWebAppFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebAppFactory _factory;
    private readonly string _token;

    public UserEndpointTests(TestWebAppFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
        _token = factory.GenerateTestToken();
        _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _token);
    }

    [Fact]
    public async Task GetMe_Authenticated_ReturnsUser()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        _factory.UserServiceMock
            .Setup(s => s.GetByIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = userId,
                Email = "alice@example.com",
                DisplayName = "Alice Money",
                ProfilePictureKey = $"profile-pictures/{userId}/avatar.jpg",
                PreferredCurrency = "USD",
                Locale = "en-US"
            });
        _factory.S3StorageServiceMock
            .Setup(s => s.GeneratePresignedDownloadUrlAsync(
                $"profile-pictures/{userId}/avatar.jpg",
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync("https://cdn.example.com/alice-avatar.jpg");
        var response = await _client.GetAsync("/api/users/me");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("alice@example.com", body);
        Assert.Contains("Alice Money", body);
        Assert.Contains("https://cdn.example.com/alice-avatar.jpg", body);
    }

    [Fact]
    public async Task GetMe_IncludesHasPasswordFromEmailIdentity()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        var userId = Guid.Parse("d1b2c3d4-0001-4000-8000-000000000001");
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            factory.GenerateTestToken(userId: userId.ToString(), email: "passworded@example.com"));
        factory.UserServiceMock
            .Setup(s => s.GetByIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = userId,
                Email = "passworded@example.com",
                PreferredCurrency = "USD",
                Locale = "en-US"
            });
        await factory.UserRepo.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Provider = AuthProvider.Email,
            ProviderSub = "passworded@example.com",
            HasPassword = true
        });

        var response = await client.GetAsync("/api/users/me");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"hasPassword\":true", body);
    }

    [Fact]
    public async Task GetMe_Unauthenticated_Returns401()
    {
        var client = _factory.CreateClient();
        var response = await client.GetAsync("/api/users/me");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetMe_FirstAuthenticatedRequest_BootstrapsMissingLocalUser()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        _factory.UserServiceMock
            .Setup(s => s.GetByIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(() => _factory.UserRepo.Users.SingleOrDefault(u => u.Id == userId));

        var response = await _client.GetAsync("/api/users/me");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var user = Assert.Single(_factory.UserRepo.Users);
        Assert.Equal(userId, user.Id);
        Assert.Equal("alice@example.com", user.Email);
        Assert.False(user.EmailConfirmed);

        var identity = Assert.Single(_factory.UserRepo.Identities);
        Assert.Equal(AuthProvider.Email, identity.Provider);
        Assert.Equal("alice@example.com", identity.ProviderSub);
        Assert.Equal(userId, identity.UserId);
    }

    [Fact]
    public async Task GetMe_FirstAuthenticatedRequest_StoresGoogleIdentityFromClaims()
    {
        var client = _factory.CreateClient();
        var userId = Guid.Parse("b1b2c3d4-0001-4000-8000-000000000001");
        var token = _factory.GenerateTestToken(
            userId: userId.ToString(),
            email: "social@example.com",
            additionalClaims:
            [
                new Claim("identities", """
                    [{"providerName":"Google","userId":"google-sub-123","providerType":"Google"}]
                    """),
                new Claim("email_verified", "true")
            ]);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        _factory.UserServiceMock
            .Setup(s => s.GetByIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(() => _factory.UserRepo.Users.SingleOrDefault(u => u.Id == userId));

        var response = await client.GetAsync("/api/users/me");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var user = Assert.Single(_factory.UserRepo.Users.Where(u => u.Id == userId));
        Assert.Equal("social@example.com", user.Email);
        Assert.True(user.EmailConfirmed);

        var identity = Assert.Single(_factory.UserRepo.Identities.Where(i => i.UserId == userId));
        Assert.Equal(AuthProvider.Google, identity.Provider);
        Assert.Equal("google-sub-123", identity.ProviderSub);
    }

    [Fact]
    public async Task GetMe_FirstAuthenticatedRequest_StoresGoogleIdentityFromJsonObjectClaim()
    {
        var client = _factory.CreateClient();
        var userId = Guid.Parse("c1b2c3d4-0001-4000-8000-000000000001");
        var token = _factory.GenerateTestToken(
            userId: userId.ToString(),
            email: "social-object@example.com",
            additionalClaims:
            [
                new Claim("identities", """
                    {"providerName":"Google","userId":"google-sub-object","providerType":"Google"}
                    """),
                new Claim("email_verified", "true")
            ]);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        _factory.UserServiceMock
            .Setup(s => s.GetByIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(() => _factory.UserRepo.Users.SingleOrDefault(u => u.Id == userId));

        var response = await client.GetAsync("/api/users/me");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var identity = Assert.Single(_factory.UserRepo.Identities.Where(i => i.UserId == userId));
        Assert.Equal(AuthProvider.Google, identity.Provider);
        Assert.Equal("google-sub-object", identity.ProviderSub);
    }

    [Fact]
    public async Task UpdateMe_ValidPayload_Returns200()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        _factory.UserServiceMock
            .Setup(s => s.UpdateProfileAsync(userId, It.Is<UserProfileUpdateDto>(d => d.PreferredCurrency == "EUR"), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = userId, Email = "alice@example.com", PreferredCurrency = "EUR", Locale = "en-US" });

        var response = await _client.PutAsJsonAsync("/api/users/me", new
        {
            preferredCurrency = "EUR"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("EUR", body);
    }

    [Fact]
    public async Task UpdateMe_AiPersonalityIntensity_Returns200()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        _factory.UserServiceMock
            .Setup(s => s.UpdateProfileAsync(
                userId,
                It.Is<UserProfileUpdateDto>(d => d.AiPersonalityIntensity == "intense"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = userId,
                Email = "alice@example.com",
                PreferredCurrency = "USD",
                Locale = "en-US",
                AiPersonalityIntensity = "intense"
            });

        var response = await _client.PutAsJsonAsync("/api/users/me", new
        {
            aiPersonalityIntensity = "intense"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"aiPersonalityIntensity\":\"intense\"", body);
    }

    [Fact]
    public async Task UpdateMe_DisplayNameAndProfilePictureKey_Returns200()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        var key = $"profile-pictures/{userId}/avatar.jpg";
        _factory.UserServiceMock
            .Setup(s => s.UpdateProfileAsync(
                userId,
                It.Is<UserProfileUpdateDto>(d =>
                    d.DisplayName == "Story Demo" &&
                    d.ProfilePictureKey == key),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User
            {
                Id = userId,
                Email = "alice@example.com",
                DisplayName = "Story Demo",
                ProfilePictureKey = key,
                PreferredCurrency = "USD",
                Locale = "en-US"
            });
        _factory.S3StorageServiceMock
            .Setup(s => s.GeneratePresignedDownloadUrlAsync(
                key,
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync("https://cdn.example.com/story-demo.jpg");

        var response = await _client.PutAsJsonAsync("/api/users/me", new
        {
            displayName = "Story Demo",
            profilePictureKey = key
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"displayName\":\"Story Demo\"", body);
        Assert.Contains("\"photoUrl\":\"https://cdn.example.com/story-demo.jpg\"", body);
    }

    [Fact]
    public async Task CreateProfilePictureUploadUrl_ReturnsPresignedUrlAndKey()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        _factory.S3StorageServiceMock
            .Setup(s => s.GeneratePresignedUploadUrlAsync(
                It.Is<string>(key =>
                    key.StartsWith($"profile-pictures/{userId}/") &&
                    key.EndsWith(".jpg")),
                "image/jpeg",
                It.IsAny<int>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync("https://s3.example.com/upload");

        var response = await _client.PostAsJsonAsync(
            "/api/users/me/profile-picture-upload-url",
            new { contentType = "image/jpeg" });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"uploadUrl\":\"https://s3.example.com/upload\"", body);
        Assert.Contains("\"profilePictureKey\":\"profile-pictures/", body);
        Assert.Contains("\"proxyUploadUrl\":\"users/me/profile-picture-upload?key=", body);
    }

    [Fact]
    public async Task UploadProfilePictureThroughApiProxy_WritesObjectToStorage()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        var key = $"profile-pictures/{userId}/avatar.png";
        _factory.S3StorageServiceMock
            .Setup(s => s.UploadAsync(
                key,
                It.IsAny<Stream>(),
                "image/png",
                It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);

        using var content = new ByteArrayContent([1, 2, 3, 4]);
        content.Headers.ContentType = new MediaTypeHeaderValue("image/png");

        var response = await _client.PutAsync(
            $"/api/users/me/profile-picture-upload?key={Uri.EscapeDataString(key)}",
            content);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        _factory.S3StorageServiceMock.Verify(s => s.UploadAsync(
            key,
            It.IsAny<Stream>(),
            "image/png",
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UploadProfilePictureThroughApiProxy_RejectsOtherUsersKey()
    {
        var otherUserKey = "profile-pictures/ffffffff-ffff-ffff-ffff-ffffffffffff/avatar.png";
        using var content = new ByteArrayContent([1, 2, 3, 4]);
        content.Headers.ContentType = new MediaTypeHeaderValue("image/png");

        var response = await _client.PutAsync(
            $"/api/users/me/profile-picture-upload?key={Uri.EscapeDataString(otherUserKey)}",
            content);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        _factory.S3StorageServiceMock.Verify(s => s.UploadAsync(
            otherUserKey,
            It.IsAny<Stream>(),
            It.IsAny<string>(),
            It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task UploadProfilePictureThroughApiProxy_WhenStorageFailsInDevelopment_ReturnsExceptionDetails()
    {
        var userId = Guid.Parse("a1b2c3d4-0001-4000-8000-000000000001");
        var key = $"profile-pictures/{userId}/storage-error.png";
        _factory.S3StorageServiceMock
            .Setup(s => s.UploadAsync(
                key,
                It.IsAny<Stream>(),
                "image/png",
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new AmazonS3Exception("MinIO bucket refused the profile upload"));

        using var content = new ByteArrayContent([1, 2, 3, 4]);
        content.Headers.ContentType = new MediaTypeHeaderValue("image/png");

        var response = await _client.PutAsync(
            $"/api/users/me/profile-picture-upload?key={Uri.EscapeDataString(key)}",
            content);

        Assert.Equal(HttpStatusCode.InternalServerError, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("\"error\":\"An unexpected error occurred\"", body);
        Assert.Contains("Amazon.S3.AmazonS3Exception", body);
        Assert.Contains("MinIO bucket refused the profile upload", body);
    }
}
