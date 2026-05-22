using Amazon.CognitoIdentityProvider;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class UserProvisioningServiceTests
{
    [Fact]
    public async Task ProvisionReviewerAsync_UseMock_CreatesLocalUserWithoutCognito()
    {
        var cognito = new Mock<IAmazonCognitoIdentityProvider>();
        var users = new InMemoryUserRepository();
        var admin = new Mock<ISubscriptionAdminService>();
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:UseMock"] = "true"
            })
            .Build();
        var services = new ServiceCollection()
            .AddSingleton(cognito.Object)
            .BuildServiceProvider();

        admin.Setup(s => s.GrantLifetimePremiumAsync(
                It.IsAny<Guid>(),
                "reviewer-provisioning",
                "review flow",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Guid userId, string _, string? __, CancellationToken ___) =>
                new AdminUserLookupResponse(
                    userId,
                    "reviewer@getconscia.com",
                    true,
                    "lifetime",
                    true));

        var service = new UserProvisioningService(
            services,
            users,
            admin.Object,
            config);

        var result = await service.ProvisionReviewerAsync(new ProvisionReviewerAccountRequest(
            "reviewer@getconscia.com",
            "ConsciaTemp123!",
            true,
            "review flow"));

        Assert.Equal("reviewer@getconscia.com", result.Email);
        Assert.True(result.IsLifetime);
        Assert.Single(users.Users);
        Assert.Single(users.Identities);
        Assert.Equal("reviewer@getconscia.com", users.Users.Single().Email);

        cognito.VerifyNoOtherCalls();
        admin.Verify(s => s.GrantLifetimePremiumAsync(
            It.IsAny<Guid>(),
            "reviewer-provisioning",
            "review flow",
            It.IsAny<CancellationToken>()), Times.Once);
    }
}
