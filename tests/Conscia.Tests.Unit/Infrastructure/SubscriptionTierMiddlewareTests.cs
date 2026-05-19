using System.Security.Claims;
using Conscia.Api.Middleware;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.DependencyInjection;

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
        var context = CreateContext(
            authenticated: true,
            tier: "Premium",
            hasPremiumMetadata: true,
            currentSubscriptionIsPremium: true);
        var middleware = new SubscriptionTierMiddleware(_ => Task.CompletedTask);

        await middleware.InvokeAsync(context);

        Assert.Equal(200, context.Response.StatusCode);
    }

    [Fact]
    public async Task PremiumEndpoint_UsesCurrentSubscriptionInsteadOfClaimCasing()
    {
        var context = CreateContext(
            authenticated: true,
            tier: "premium",
            hasPremiumMetadata: true,
            currentSubscriptionIsPremium: true);
        var middleware = new SubscriptionTierMiddleware(_ => Task.CompletedTask);

        await middleware.InvokeAsync(context);

        Assert.Equal(200, context.Response.StatusCode);
    }

    [Fact]
    public async Task PremiumEndpoint_CurrentPremiumSubscription_PassesEvenWhenTokenTierIsStale()
    {
        var context = CreateContext(
            authenticated: true,
            tier: "Free",
            hasPremiumMetadata: true,
            currentSubscriptionIsPremium: true);
        var middleware = new SubscriptionTierMiddleware(_ => Task.CompletedTask);

        await middleware.InvokeAsync(context);

        Assert.Equal(200, context.Response.StatusCode);
    }

    private static HttpContext CreateContext(
        bool authenticated,
        string? tier,
        bool hasPremiumMetadata,
        bool currentSubscriptionIsPremium = false)
    {
        var context = new DefaultHttpContext();
        context.Response.Body = new MemoryStream();
        context.RequestServices = new ServiceCollection()
            .AddSingleton<ISubscriptionService>(
                new FakeSubscriptionService(currentSubscriptionIsPremium))
            .BuildServiceProvider();

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

    private sealed class FakeSubscriptionService(bool isPremium) : ISubscriptionService
    {
        public Task<UserSubscription> VerifyiOSReceiptAsync(
            Guid userId,
            string receiptData,
            CancellationToken ct = default) =>
            throw new NotSupportedException();

        public Task<UserSubscription> VerifyAndroidTokenAsync(
            Guid userId,
            string purchaseToken,
            CancellationToken ct = default) =>
            throw new NotSupportedException();

        public Task<UserSubscription?> GetStatusAsync(
            Guid userId,
            CancellationToken ct = default) =>
            Task.FromResult<UserSubscription?>(null);

        public Task<bool> IsPremiumAsync(Guid userId, CancellationToken ct = default) =>
            Task.FromResult(isPremium);
    }
}
