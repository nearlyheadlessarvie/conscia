using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Moq;
namespace Conscia.Tests.Unit.Api;

public class AuthEndpointTests
{
    [Fact]
    public async Task Register_ValidCredentials_Returns202AndRequiresConfirmation()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email = $"test-{Guid.NewGuid()}@example.com",
            password = "SecureP@ss123"
        });

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(body);
        Assert.Equal("True", body!["requiresConfirmation"].ToString());
        Assert.Equal("True", body["success"].ToString());
        Assert.False(body.ContainsKey("accessToken"));
    }

    [Fact]
    public async Task Register_WithBearerToken_DoesNotBootstrapTokenUser()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        var email = $"stale-token-register-{Guid.NewGuid()}@example.com";
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            factory.GenerateTestToken(
                userId: "aaaaaaaa-0000-4000-8000-000000000001",
                email: "stale-token@example.com"));

        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "SecureP@ss123"
        });

        Assert.Equal(HttpStatusCode.Accepted, response.StatusCode);
        Assert.Contains(factory.UserRepo.Users, user => user.Email == email);
        Assert.DoesNotContain(factory.UserRepo.Users, user => user.Email == "stale-token@example.com");
    }

    [Fact]
    public async Task Confirm_ValidCode_Returns200()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        var email = $"confirm-{Guid.NewGuid()}@example.com";

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "SecureP@ss123"
        });

        var response = await client.PostAsJsonAsync("/api/auth/confirm", new
        {
            email,
            confirmationCode = "123456"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(body);
        Assert.Equal("True", body!["success"].ToString());
    }

    [Fact]
    public async Task ResendConfirmation_ExistingUser_Returns200()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        var email = $"resend-{Guid.NewGuid()}@example.com";

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "SecureP@ss123"
        });

        var response = await client.PostAsJsonAsync("/api/auth/resend-confirmation", new
        {
            email
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task StartPasswordReset_ExistingUser_Returns200()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        var email = $"reset-start-{Guid.NewGuid()}@example.com";

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "SecureP@ss123"
        });

        var response = await client.PostAsJsonAsync("/api/auth/password-reset/start", new
        {
            email
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(body);
        Assert.Equal("True", body!["success"].ToString());
    }

    [Fact]
    public async Task ConfirmPasswordReset_ExistingUser_Returns200()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        var email = $"reset-confirm-{Guid.NewGuid()}@example.com";

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "SecureP@ss123"
        });

        var response = await client.PostAsJsonAsync("/api/auth/password-reset/confirm", new
        {
            email,
            confirmationCode = "123456",
            password = "FreshPass123"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(body);
        Assert.Equal("True", body!["success"].ToString());
    }

    [Fact]
    public async Task Login_ValidCredentials_Returns200()
    {
        await using var factory = new TestWebAppFactory();
        var email = $"login-{Guid.NewGuid()}@example.com";

        await using (var scope = factory.Services.CreateAsyncScope())
        {
            var auth = scope.ServiceProvider.GetRequiredService<IAuthService>();
            await auth.RegisterAsync(email, "password123");
            await auth.ConfirmRegistrationAsync(email, "123456");
        }

        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email,
            password = "password123"
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Login_UnconfirmedEmail_Returns409AndRequiresConfirmation()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        var email = $"pending-login-{Guid.NewGuid()}@example.com";

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "password123"
        });

        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email,
            password = "password123"
        });

        Assert.Equal(HttpStatusCode.Conflict, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(body);
        Assert.Equal("True", body!["requiresConfirmation"].ToString());
    }

    [Fact]
    public async Task Login_InvalidCredentials_Returns401()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "nonexistent@example.com",
            password = "wrong"
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Login_RateLimit_IsPartitionedByAnonymousIp()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        for (var i = 0; i < 5; i++)
        {
            var response = await PostLoginAsync(client, "203.0.113.10");

            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        }

        var limitedResponse = await PostLoginAsync(client, "203.0.113.10");
        var otherIpResponse = await PostLoginAsync(client, "203.0.113.11");

        Assert.Equal(HttpStatusCode.TooManyRequests, limitedResponse.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, otherIpResponse.StatusCode);
    }

    [Fact]
    public async Task Register_EmptyEmail_Returns400()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email = "",
            password = "password123"
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GoogleLogin_EndpointRemoved_Returns404()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/google", new
        {
            idToken = "mock-google-id-token"
        });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task AppleLogin_EndpointRemoved_Returns404()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/apple", new
        {
            identityToken = "mock-apple-identity-token",
            authorizationCode = "mock-auth-code"
        });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task Refresh_ValidRefreshToken_Returns200()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        var email = $"refresh-{Guid.NewGuid()}@example.com";

        await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password = "password123"
        });
        await client.PostAsJsonAsync("/api/auth/confirm", new
        {
            email,
            confirmationCode = "123456"
        });

        var login = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email,
            password = "password123"
        });

        var loginBody = await login.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(loginBody);

        var response = await client.PostAsJsonAsync("/api/auth/refresh", new
        {
            refreshToken = loginBody!["refreshToken"]?.ToString()
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(body);
        Assert.True(body!.ContainsKey("accessToken"));
        Assert.True(body.ContainsKey("refreshToken"));
        Assert.True(body.ContainsKey("userId"));
    }

    [Fact]
    public async Task Refresh_InvalidRefreshToken_Returns401()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/refresh", new
        {
            refreshToken = "not-a-valid-refresh-token"
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Refresh_EmptyRefreshToken_Returns400()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/refresh", new
        {
            refreshToken = ""
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task SetPassword_Authenticated_Returns204()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();
        var token = factory.GenerateTestToken();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue(
            "Bearer",
            token);

        var response = await client.PostAsJsonAsync("/api/auth/password", new
        {
            currentPassword = "OldPass123",
            password = "StrongPass123"
        });

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        factory.CurrentUserPasswordServiceMock.Verify(
            s => s.SetPasswordAsync(
                It.IsAny<System.Security.Claims.ClaimsPrincipal>(),
                "StrongPass123",
                "OldPass123",
                token,
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task SetPassword_Unauthenticated_Returns401()
    {
        await using var factory = new TestWebAppFactory();
        using var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/password", new
        {
            password = "StrongPass123"
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private static Task<HttpResponseMessage> PostLoginAsync(HttpClient client, string forwardedFor)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/auth/login")
        {
            Content = JsonContent.Create(new
            {
                email = "nonexistent@example.com",
                password = "wrong"
            })
        };
        request.Headers.TryAddWithoutValidation("X-Forwarded-For", forwardedFor);

        return client.SendAsync(request);
    }
}
