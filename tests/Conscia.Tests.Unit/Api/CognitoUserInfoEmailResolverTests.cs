using System.Net;
using Conscia.Api.Middleware;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

namespace Conscia.Tests.Unit.Api;

public class CognitoUserInfoEmailResolverTests
{
    [Fact]
    public async Task ResolveAsync_ReturnsNormalizedEmailAndCachesByAccessToken()
    {
        var handler = new RecordingHandler(
            """
            {"email":" Alice@Example.com ","email_verified":true}
            """);
        var resolver = new CognitoUserInfoEmailResolver(
            new HttpClient(handler),
            new MemoryCache(new MemoryCacheOptions()),
            Configuration("https://login.getconscia.com"),
            NullLogger<CognitoUserInfoEmailResolver>.Instance);

        var first = await resolver.ResolveAsync("access-token", CancellationToken.None);
        var second = await resolver.ResolveAsync("access-token", CancellationToken.None);

        Assert.NotNull(first);
        Assert.Equal("alice@example.com", first.Email);
        Assert.True(first.EmailVerified);
        Assert.Same(first, second);
        Assert.Equal(1, handler.CallCount);
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
            Assert.Equal("access-token", request.Headers.Authorization?.Parameter);

            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(content)
            });
        }
    }
}
