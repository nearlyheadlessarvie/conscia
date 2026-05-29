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
        var middleware = new CurrentUserBootstrapMiddleware(
            httpContext =>
            {
                nextCalled = true;
                Assert.Equal(existingUserId.ToString(), httpContext.User.FindFirstValue(ClaimTypes.NameIdentifier));
                return Task.CompletedTask;
            },
            NullLogger<CurrentUserBootstrapMiddleware>.Instance);
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
}
