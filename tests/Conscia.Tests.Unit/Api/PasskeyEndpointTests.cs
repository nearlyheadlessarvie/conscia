using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.DTOs;
using Conscia.Application.Exceptions;
using Conscia.Application.Interfaces;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class PasskeyEndpointTests
{
    [Fact]
    public async Task StartRegistration_NonCognitoSession_Returns403()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());

        var response = await client.PostAsync("/api/auth/passkeys/register/start", content: null);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task CompleteRegistration_NonCognitoSession_Returns403()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", factory.GenerateTestToken());

        var response = await client.PostAsJsonAsync("/api/auth/passkeys/register/complete", new
        {
            credential = "{\"id\":\"credential-id\"}"
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task StartLogin_ReturnsChallengePayload()
    {
        await using var factory = new TestWebAppFactory();
        factory.PasskeyAuthServiceMock
            .Setup(service => service.StartAuthenticationAsync(
                "demo@example.com",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new StartPasskeyAuthenticationResponse(
                "challenge-session",
                "WEB_AUTHN",
                "{\"challenge\":\"abc\"}"));

        using var client = factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/passkeys/login/start", new
        {
            email = "demo@example.com"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(body);
        Assert.Equal("challenge-session", body!["session"]);
        Assert.Equal("WEB_AUTHN", body["challengeName"]);
        Assert.Equal("{\"challenge\":\"abc\"}", body["credentialRequestOptions"]);
    }

    [Fact]
    public async Task StartLogin_PasskeyUnavailable_ReturnsBadRequest()
    {
        await using var factory = new TestWebAppFactory();
        factory.PasskeyAuthServiceMock
            .Setup(service => service.StartAuthenticationAsync(
                "demo@example.com",
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new PasskeyAuthenticationUnavailableException(
                "No passkey is registered for this account yet. Sign in with your password, then set up a passkey in Settings."));

        using var client = factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/passkeys/login/start", new
        {
            email = "demo@example.com"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(body);
        Assert.Equal(
            "No passkey is registered for this account yet. Sign in with your password, then set up a passkey in Settings.",
            body!["error"]);
    }

    [Fact]
    public async Task CompleteLogin_ReturnsTokens()
    {
        await using var factory = new TestWebAppFactory();
        factory.PasskeyAuthServiceMock
            .Setup(service => service.CompleteAuthenticationAsync(
                "demo@example.com",
                "challenge-session",
                "WEB_AUTHN",
                "{\"id\":\"credential-id\"}",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AuthResult
            {
                Success = true,
                AccessToken = "access-token",
                RefreshToken = "refresh-token",
                UserId = Guid.NewGuid().ToString()
            });

        using var client = factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/passkeys/login/complete", new
        {
            email = "demo@example.com",
            session = "challenge-session",
            challengeName = "WEB_AUTHN",
            credential = "{\"id\":\"credential-id\"}"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, string>>();
        Assert.NotNull(body);
        Assert.Equal("access-token", body!["accessToken"]);
        Assert.Equal("refresh-token", body["refreshToken"]);
        Assert.False(string.IsNullOrWhiteSpace(body["userId"]));
    }
}
