using System.Net;
using System.Security.Claims;
using Conscia.Api.Middleware;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

namespace Conscia.Tests.Unit.Api;

public class CognitoUserInfoClaimsMiddlewareTests
{
    [Fact]
    public async Task InvokeAsync_AddsUserInfoClaimsToCurrentPrincipalAndCachesThem()
    {
        var token = "header.payload.signature";
        var handler = new RecordingHandler(
            """
            {"sub":"user-123","email":"alice@example.com","email_verified":"true"}
            """);
        using var httpClient = new HttpClient(handler);
        using var cache = new MemoryCache(new MemoryCacheOptions());
        var provider = new CognitoUserInfoClaimsProvider(
            httpClient,
            cache,
            Configuration("https://login.getconscia.com"),
            NullLogger<CognitoUserInfoClaimsProvider>.Instance);

        var firstContext = Context(token);
        var middleware = new CognitoUserInfoClaimsMiddleware(
            context =>
            {
                Assert.Equal("alice@example.com", context.User.FindFirstValue(ClaimTypes.Email));
                Assert.Equal("alice@example.com", context.User.FindFirstValue("email"));
                Assert.Equal("true", context.User.FindFirstValue("email_verified"));
                return Task.CompletedTask;
            },
            provider);

        await middleware.InvokeAsync(firstContext);
        await middleware.InvokeAsync(Context(token));

        Assert.Equal(1, handler.CallCount);
    }

    [Fact]
    public async Task InvokeAsync_KeepsTokenClaimsWhenUserInfoFails()
    {
        var provider = new CognitoUserInfoClaimsProvider(
            new HttpClient(new ThrowingHandler()),
            new MemoryCache(new MemoryCacheOptions()),
            Configuration("https://login.getconscia.com"),
            NullLogger<CognitoUserInfoClaimsProvider>.Instance);
        var middleware = new CognitoUserInfoClaimsMiddleware(
            context =>
            {
                Assert.Equal("user-123", context.User.FindFirstValue("sub"));
                Assert.Null(context.User.FindFirstValue(ClaimTypes.Email));
                return Task.CompletedTask;
            },
            provider);

        await middleware.InvokeAsync(Context("token"));
    }

    private static DefaultHttpContext Context(string token)
    {
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                [
                    new Claim(ClaimTypes.NameIdentifier, "user-123"),
                    new Claim("sub", "user-123")
                ],
                "Test"))
        };
        context.Request.Headers.Authorization = $"Bearer {token}";
        return context;
    }

    private static IConfiguration Configuration(string loginDomain) =>
        new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:Cognito:LoginDomain"] = loginDomain
            })
            .Build();

    private sealed class RecordingHandler(string content) : HttpMessageHandler
    {
        public int CallCount { get; private set; }

        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            CallCount++;
            Assert.Equal(HttpMethod.Get, request.Method);
            Assert.Equal("https://login.getconscia.com/oauth2/userInfo", request.RequestUri?.ToString());
            Assert.Equal("Bearer", request.Headers.Authorization?.Scheme);
            Assert.Equal("header.payload.signature", request.Headers.Authorization?.Parameter);

            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(content)
            });
        }
    }

    private sealed class ThrowingHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken) =>
            throw new HttpRequestException("network unavailable");
    }
}
