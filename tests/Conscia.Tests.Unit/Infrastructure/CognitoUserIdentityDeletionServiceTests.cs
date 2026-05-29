using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Domain.Entities;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class CognitoUserIdentityDeletionServiceTests
{
    private readonly Mock<IAmazonCognitoIdentityProvider> _cognito = new();
    private readonly CognitoUserIdentityDeletionService _service;

    public CognitoUserIdentityDeletionServiceTests()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:Cognito:UserPoolId"] = "pool-123"
            })
            .Build();

        _service = new CognitoUserIdentityDeletionService(_cognito.Object, configuration);
    }

    [Fact]
    public async Task DeleteUserAsync_DeletesCognitoUserByEmailAlias()
    {
        var user = new User
        {
            Id = Guid.Parse("62a5d765-97c5-432f-996b-3ddfb65be748"),
            Email = "Delete@Example.com "
        };

        _cognito
            .Setup(c => c.AdminDeleteUserAsync(
                It.Is<AdminDeleteUserRequest>(r =>
                    r.UserPoolId == "pool-123" &&
                    r.Username == "delete@example.com"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AdminDeleteUserResponse());

        await _service.DeleteUserAsync(user);

        _cognito.VerifyAll();
    }

    [Fact]
    public async Task DeleteUserAsync_IgnoresAlreadyDeletedCognitoUser()
    {
        var user = new User
        {
            Id = Guid.Parse("62a5d765-97c5-432f-996b-3ddfb65be748"),
            Email = "delete@example.com"
        };

        _cognito
            .Setup(c => c.AdminDeleteUserAsync(
                It.IsAny<AdminDeleteUserRequest>(),
                It.IsAny<CancellationToken>()))
            .ThrowsAsync(new UserNotFoundException("User does not exist."));

        await _service.DeleteUserAsync(user);
    }
}
