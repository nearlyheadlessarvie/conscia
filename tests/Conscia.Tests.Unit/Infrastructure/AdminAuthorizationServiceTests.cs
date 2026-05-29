using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class AdminAuthorizationServiceTests
{
    [Fact]
    public async Task IsAuthorizedAsync_UsesCommaSeparatedBootstrapEmails()
    {
        var userId = Guid.NewGuid();
        var identity = new UserIdentity
        {
            UserId = userId,
            Provider = AuthProvider.Email,
            ProviderSub = "ops@getconscia.com",
            Role = UserIdentityRole.Member
        };
        var users = new Mock<IUserRepository>();
        users
            .Setup(repo => repo.GetIdentitiesByUserAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync([identity]);
        users
            .Setup(repo => repo.UpdateIdentityAsync(It.IsAny<UserIdentity>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((UserIdentity updatedIdentity, CancellationToken _) => updatedIdentity);
        var configuration = new ConfigurationManager();
        configuration.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["AdminBootstrap:Emails"] = "founder@getconscia.com, ops@getconscia.com"
        });
        var service = new AdminAuthorizationService(users.Object, configuration);

        var authorized = await service.IsAuthorizedAsync(userId, "OPS@getconscia.com");

        Assert.True(authorized);
        Assert.Equal(UserIdentityRole.Admin, identity.Role);
        users.Verify(
            repo => repo.UpdateIdentityAsync(identity, It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
