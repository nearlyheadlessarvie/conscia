using System.Security.Claims;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class CurrentUserPasswordServiceTests
{
    private readonly Mock<IAmazonCognitoIdentityProvider> _cognito = new();
    private readonly InMemoryUserRepository _repo = new();
    private readonly CurrentUserPasswordService _service;

    public CurrentUserPasswordServiceTests()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Auth:Cognito:UserPoolId"] = "pool-123"
            })
            .Build();

        _service = new CurrentUserPasswordService(_cognito.Object, _repo, config);
    }

    [Fact]
    public async Task SetPasswordAsync_ExistingPassword_UsesCurrentPasswordChallenge()
    {
        var user = await SeedUserAsync(hasPassword: true);
        _cognito
            .Setup(c => c.ChangePasswordAsync(
                It.Is<ChangePasswordRequest>(r =>
                    r.AccessToken == "access-token" &&
                    r.PreviousPassword == "OldPass123" &&
                    r.ProposedPassword == "NewPass123"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ChangePasswordResponse());

        await _service.SetPasswordAsync(
            Principal(user.Email),
            "NewPass123",
            "OldPass123",
            "access-token");

        _cognito.Verify(c => c.ChangePasswordAsync(
            It.IsAny<ChangePasswordRequest>(),
            It.IsAny<CancellationToken>()), Times.Once);
        _cognito.Verify(c => c.AdminSetUserPasswordAsync(
            It.IsAny<AdminSetUserPasswordRequest>(),
            It.IsAny<CancellationToken>()), Times.Never);
        Assert.True(_repo.Identities.Single().HasPassword);
    }

    [Fact]
    public async Task SetPasswordAsync_NoPassword_UsesAdminSetPasswordAndMarksIdentity()
    {
        var user = await SeedUserAsync(hasPassword: false);
        _cognito
            .Setup(c => c.AdminSetUserPasswordAsync(
                It.Is<AdminSetUserPasswordRequest>(r =>
                    r.UserPoolId == "pool-123" &&
                    r.Username == "cognito-user" &&
                    r.Password == "NewPass123" &&
                    r.Permanent == true),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AdminSetUserPasswordResponse());

        await _service.SetPasswordAsync(Principal(user.Email), "NewPass123");

        _cognito.Verify(c => c.AdminSetUserPasswordAsync(
            It.IsAny<AdminSetUserPasswordRequest>(),
            It.IsAny<CancellationToken>()), Times.Once);
        _cognito.Verify(c => c.ChangePasswordAsync(
            It.IsAny<ChangePasswordRequest>(),
            It.IsAny<CancellationToken>()), Times.Never);
        Assert.True(_repo.Identities.Single().HasPassword);
    }

    [Fact]
    public async Task SetPasswordAsync_ExistingPasswordWithoutCurrentPassword_Throws()
    {
        var user = await SeedUserAsync(hasPassword: true);

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            _service.SetPasswordAsync(Principal(user.Email), "NewPass123"));

        Assert.Equal("Current password is required.", ex.Message);
    }

    private async Task<User> SeedUserAsync(bool hasPassword)
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "person@example.com",
            EmailConfirmed = true
        };
        await _repo.AddAsync(user);
        await _repo.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Email,
            ProviderSub = user.Email,
            HasPassword = hasPassword
        });

        return user;
    }

    private static ClaimsPrincipal Principal(string email) => new(
        new ClaimsIdentity(
        [
            new Claim("cognito:username", "cognito-user"),
            new Claim(ClaimTypes.Email, email)
        ],
        "Test"));
}
