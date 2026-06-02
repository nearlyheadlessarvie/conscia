using System.Security.Claims;
using Amazon.DynamoDBv2.Model;
using Conscia.Api.Middleware;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Api;

public class CurrentUserBootstrapMiddlewareTests
{
    [Fact]
    public async Task InvokeAsync_ReusesExistingLocalUserWithSameEmail_WhenTokenSubIsNew()
    {
        var tokenUserId = Guid.Parse("aaaaaaaa-0000-4000-8000-000000000001");
        var existingUserId = Guid.Parse("bbbbbbbb-0000-4000-8000-000000000001");
        var existingUser = new User
        {
            Id = existingUserId,
            Email = "alice@example.com",
            EmailConfirmed = false
        };
        var nextCalled = false;
        var middleware = CreateMiddleware(
            httpContext =>
            {
                nextCalled = true;
                Assert.Equal(existingUserId.ToString(), httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier));
                return Task.CompletedTask;
            });
        var users = new Mock<IUserRepository>();
        users
            .Setup(repo => repo.GetByIdAsync(tokenUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);
        users
            .Setup(repo => repo.GetByEmailAsync("alice@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync(existingUser);
        users
            .Setup(repo => repo.GetByProviderAsync(AuthProvider.Email, "alice@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);
        users
            .Setup(repo => repo.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new TransactionCanceledException(
                "Transaction cancelled, please refer cancellation reasons for specific reasons [None, ConditionalCheckFailed]"));
        users
            .Setup(repo => repo.AddIdentityAsync(It.IsAny<UserIdentity>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserIdentity identity, CancellationToken _) => identity);
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                [
                    new Claim(ClaimTypes.NameIdentifier, tokenUserId.ToString()),
                    new Claim(ClaimTypes.Email, " Alice@Example.com "),
                    new Claim("email_verified", "true")
                ],
                "Test"))
        };

        await middleware.InvokeAsync(context, users.Object);

        Assert.True(nextCalled);
        Assert.True(existingUser.EmailConfirmed);
        users.Verify(repo => repo.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Never);
        users.Verify(repo => repo.UpdateAsync(existingUser, It.IsAny<CancellationToken>()), Times.Once);
        users.Verify(repo => repo.AddIdentityAsync(
            It.Is<UserIdentity>(identity =>
                identity.UserId == existingUserId &&
                identity.Provider == AuthProvider.Email &&
                identity.ProviderSub == "alice@example.com"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task InvokeAsync_ReusesExistingSocialIdentity_WhenEmailClaimIsMissing()
    {
        var tokenUserId = Guid.Parse("aaaaaaaa-0000-4000-8000-000000000002");
        var existingUserId = Guid.Parse("bbbbbbbb-0000-4000-8000-000000000002");
        var existingUser = new User
        {
            Id = existingUserId,
            Email = "social@example.com",
            EmailConfirmed = true,
            HasCompletedOnboarding = true
        };
        var resolver = new FakeUserInfoEmailResolver();
        var middleware = CreateMiddleware(
            httpContext =>
            {
                Assert.Equal(
                    existingUserId.ToString(),
                    httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier));
                Assert.Equal("social@example.com", httpContext.User.FindFirstValue(ClaimTypes.Email));
                return Task.CompletedTask;
            },
            resolver);
        var users = new Mock<IUserRepository>();
        users
            .Setup(repo => repo.GetByProviderAsync(
                AuthProvider.Google,
                "google-sub-123",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(existingUser);
        users
            .Setup(repo => repo.GetByIdAsync(tokenUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                [
                    new Claim(ClaimTypes.NameIdentifier, tokenUserId.ToString()),
                    new Claim("identities", """
                        {"providerName":"Google","userId":"google-sub-123"}
                        """)
                ],
                "Test"))
        };

        await middleware.InvokeAsync(context, users.Object);

        users.Verify(repo => repo.GetByEmailAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
        users.Verify(repo => repo.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Never);
        users.Verify(repo => repo.AddIdentityAsync(It.IsAny<UserIdentity>(), It.IsAny<CancellationToken>()), Times.Never);
        Assert.Equal(0, resolver.CallCount);
    }

    [Fact]
    public async Task InvokeAsync_UsesTokenUserId_WhenEmailClaimIsMissingAndEmptyEmailIdentityExists()
    {
        var tokenUserId = Guid.Parse("59ca55dc-40b1-705a-e401-896fec9c84d6");
        var staleUserId = Guid.Parse("093a85ec-e0d1-7005-8c21-41c3341e273c");
        var tokenUser = new User
        {
            Id = tokenUserId,
            Email = "story-demo@example.com",
            EmailConfirmed = true
        };
        var staleUser = new User
        {
            Id = staleUserId,
            Email = "nearlyheadlessarvie@gmail.com",
            EmailConfirmed = true
        };
        var resolver = new FakeUserInfoEmailResolver();
        var middleware = CreateMiddleware(
            httpContext =>
            {
                Assert.Equal(
                    tokenUserId.ToString(),
                    httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier));
                Assert.Equal("story-demo@example.com", httpContext.User.FindFirstValue(ClaimTypes.Email));
                return Task.CompletedTask;
            },
            resolver);
        var users = new Mock<IUserRepository>();
        users
            .Setup(repo => repo.GetByProviderAsync(AuthProvider.Email, string.Empty, It.IsAny<CancellationToken>()))
            .ReturnsAsync(staleUser);
        users
            .Setup(repo => repo.GetByIdAsync(tokenUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(tokenUser);
        users
            .Setup(repo => repo.AddIdentityAsync(It.IsAny<UserIdentity>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserIdentity identity, CancellationToken _) => identity);
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                [
                    new Claim(ClaimTypes.NameIdentifier, tokenUserId.ToString())
                ],
                "Test"))
        };

        await middleware.InvokeAsync(context, users.Object);

        users.Verify(
            repo => repo.GetByProviderAsync(AuthProvider.Email, string.Empty, It.IsAny<CancellationToken>()),
            Times.Never);
        users.Verify(repo => repo.GetByEmailAsync(It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
        users.Verify(repo => repo.AddIdentityAsync(
            It.Is<UserIdentity>(identity =>
                identity.UserId == tokenUserId &&
                identity.Provider == AuthProvider.Email &&
                identity.ProviderSub == "story-demo@example.com"),
            It.IsAny<CancellationToken>()), Times.Once);
        Assert.Equal(0, resolver.CallCount);
    }

    [Fact]
    public async Task InvokeAsync_HydratesMissingEmailFromCognitoUserInfo_WhenLocalUserDoesNotExist()
    {
        var tokenUserId = Guid.Parse("aaaaaaaa-0000-4000-8000-000000000003");
        var resolver = new FakeUserInfoEmailResolver(new CognitoUserInfoEmail("social@example.com", true));
        var middleware = CreateMiddleware(
            httpContext =>
            {
                Assert.Equal(tokenUserId.ToString(), httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier));
                Assert.Equal("social@example.com", httpContext.User.FindFirstValue(ClaimTypes.Email));
                Assert.Equal("true", httpContext.User.FindFirstValue("email_verified"));
                return Task.CompletedTask;
            },
            resolver);
        var users = new Mock<IUserRepository>();
        users
            .Setup(repo => repo.GetByIdAsync(tokenUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);
        users
            .Setup(repo => repo.GetByEmailAsync("social@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);
        users
            .Setup(repo => repo.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User user, CancellationToken _) => user);
        users
            .Setup(repo => repo.AddIdentityAsync(It.IsAny<UserIdentity>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserIdentity identity, CancellationToken _) => identity);
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                [
                    new Claim(ClaimTypes.NameIdentifier, tokenUserId.ToString())
                ],
                "Test"))
        };
        context.Request.Headers.Authorization = "Bearer access-token";

        await middleware.InvokeAsync(context, users.Object);

        Assert.Equal(1, resolver.CallCount);
        users.Verify(repo => repo.AddAsync(
            It.Is<User>(user =>
                user.Id == tokenUserId &&
                user.Email == "social@example.com" &&
                user.EmailConfirmed),
            It.IsAny<CancellationToken>()), Times.Once);
        users.Verify(repo => repo.AddIdentityAsync(
            It.Is<UserIdentity>(identity =>
                identity.UserId == tokenUserId &&
                identity.Provider == AuthProvider.Email &&
                identity.ProviderSub == "social@example.com"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task InvokeAsync_ReloadsUser_WhenConcurrentBootstrapCreatesSameSocialUser()
    {
        var tokenUserId = Guid.Parse("aaaaaaaa-0000-4000-8000-000000000004");
        var existingUser = new User
        {
            Id = tokenUserId,
            Email = "social@example.com",
            EmailConfirmed = true
        };
        var nextCalled = false;
        var middleware = CreateMiddleware(httpContext =>
        {
            nextCalled = true;
            Assert.Equal(tokenUserId.ToString(), httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier));
            return Task.CompletedTask;
        });
        var users = new Mock<IUserRepository>();
        users
            .SetupSequence(repo => repo.GetByProviderAsync(
                AuthProvider.Google,
                "google-sub-123",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null)
            .ReturnsAsync(existingUser);
        users
            .SetupSequence(repo => repo.GetByIdAsync(tokenUserId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null)
            .ReturnsAsync(existingUser);
        users
            .Setup(repo => repo.GetByEmailAsync("social@example.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);
        users
            .Setup(repo => repo.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new TransactionCanceledException(
                "Transaction cancelled, please refer cancellation reasons for specific reasons [ConditionalCheckFailed, ConditionalCheckFailed]"));
        var context = new DefaultHttpContext
        {
            User = new ClaimsPrincipal(new ClaimsIdentity(
                [
                    new Claim(ClaimTypes.NameIdentifier, tokenUserId.ToString()),
                    new Claim(ClaimTypes.Email, "social@example.com"),
                    new Claim("email_verified", "true"),
                    new Claim("identities", """
                        {"providerName":"Google","userId":"google-sub-123"}
                        """)
                ],
                "Test"))
        };

        await middleware.InvokeAsync(context, users.Object);

        Assert.True(nextCalled);
        users.Verify(repo => repo.AddAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()), Times.Once);
        users.Verify(repo => repo.AddIdentityAsync(It.IsAny<UserIdentity>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    private static CurrentUserBootstrapMiddleware CreateMiddleware(
        RequestDelegate next,
        ICognitoUserInfoEmailResolver? resolver = null) =>
        new(
            next,
            NullLogger<CurrentUserBootstrapMiddleware>.Instance,
            resolver ?? new FakeUserInfoEmailResolver());

    private sealed class FakeUserInfoEmailResolver(CognitoUserInfoEmail? result = null)
        : ICognitoUserInfoEmailResolver
    {
        public int CallCount { get; private set; }

        public Task<CognitoUserInfoEmail?> ResolveAsync(string accessToken, CancellationToken ct)
        {
            CallCount++;
            return Task.FromResult(result);
        }
    }
}
