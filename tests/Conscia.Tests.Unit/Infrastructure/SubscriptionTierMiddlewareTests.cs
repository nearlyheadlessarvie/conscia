using System.Security.Claims;
using Conscia.Api.Middleware;
using Microsoft.AspNetCore.Http;

namespace Conscia.Tests.Unit.Infrastructure;

public class SubscriptionTierMiddlewareTests
{
    [Fact]
    public async Task NonPremiumEndpoint_AllowsAnyUser()
    {
        var context = CreateContext(authenticated: false, tier: null, hasPremiumMetadata: false);
        var middleware = new SubscriptionTierMiddleware(_ => Task.CompletedTask);

        await middleware.InvokeAsync(context);

        Assert.Equal(200, context.Response.StatusCode);
    }

    [Fact]
    public async Task PremiumEndpoint_UnauthenticatedUser_Returns401()
    {
        var context = CreateContext(authenticated: false, tier: null, hasPremiumMetadata: true);
        var middleware = new SubscriptionTierMiddleware(_ => Task.CompletedTask);

        await middleware.InvokeAsync(context);

        Assert.Equal(401, context.Response.StatusCode);
    }

    [Fact]
    public async Task PremiumEndpoint_FreeTierUser_Returns403()
    {
        var context = CreateContext(authenticated: true, tier: "Free", hasPremiumMetadata: true);
        var middleware = new SubscriptionTierMiddleware(_ => Task.CompletedTask);

        await middleware.InvokeAsync(context);

        Assert.Equal(403, context.Response.StatusCode);
    }

    [Fact]
    public async Task PremiumEndpoint_PremiumUser_Passes()
    {
        var context = CreateContext(authenticated: true, tier: "Premium", hasPremiumMetadata: true);
        var middleware = new SubscriptionTierMiddleware(_ => Task.CompletedTask);

        await middleware.InvokeAsync(context);

        Assert.Equal(200, context.Response.StatusCode);
    }

    [Fact]
    public async Task PremiumEndpoint_TierCaseInsensitive_Passes()
    {
        var context = CreateContext(authenticated: true, tier: "premium", hasPremiumMetadata: true);
        var middleware = new SubscriptionTierMiddleware(_ => Task.CompletedTask);

        await middleware.InvokeAsync(context);

        Assert.Equal(200, context.Response.StatusCode);
    }

    private static HttpContext CreateContext(bool authenticated, string? tier, bool hasPremiumMetadata)
    {
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();

        if (authenticated)
        {
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, Guid.NewGuid().ToString()),
                new(ClaimTypes.Email, "test@test.com")
            };
            if (tier is not null)
                claims.Add(new Claim("tier", tier));

            var identity = new ClaimsIdentity(claims, "TestAuth");
            context.User = new ClaimsPrincipal(identity);
        }

        var endpointMetadata = new List<object>();
        if (hasPremiumMetadata)
            endpointMetadata.Add(new RequirePremiumAttribute());

        context.SetEndpoint(new Endpoint(_ => Task.CompletedTask, new EndpointMetadataCollection(endpointMetadata), "test"));

        return context;
    }
}
