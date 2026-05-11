using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class FamilySpaceServiceTests
{
    private readonly Mock<IFamilySpaceRepository> _repo = new();
    private readonly Mock<ISubscriptionService> _subscriptions = new();

    private FamilySpaceService CreateService() =>
        new(_repo.Object, _subscriptions.Object, NullLogger<FamilySpaceService>.Instance);

    [Fact]
    public async Task CreateAsync_PremiumUserWithoutFamily_CreatesSpaceAndOwnerMembership()
    {
        var userId = Guid.NewGuid();
        _subscriptions.Setup(s => s.IsPremiumAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyMember?)null);
        _repo.Setup(r => r.CreateWithOwnerAsync(
                It.IsAny<FamilySpace>(),
                It.IsAny<FamilyMember>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilySpace space, FamilyMember _, CancellationToken _) => space);

        var result = await CreateService().CreateAsync(userId, "Santos Household", "PHP");

        Assert.Equal("Santos Household", result.Name);
        Assert.Equal("PHP", result.CurrencyCode);
        _repo.Verify(r => r.CreateWithOwnerAsync(
            It.Is<FamilySpace>(s => s.CreatedByUserId == userId && !s.IsReadOnly),
            It.Is<FamilyMember>(m => m.UserId == userId && m.Role == FamilyMemberRole.Owner),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_FreeUser_ThrowsUpgradeRequired()
    {
        var userId = Guid.NewGuid();
        _subscriptions.Setup(s => s.IsPremiumAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().CreateAsync(userId, "Santos Household", "PHP"));

        Assert.Equal("Family Space requires Premium.", error.Message);
    }

    [Fact]
    public async Task CreateAsync_UserAlreadyInFamily_Throws()
    {
        var userId = Guid.NewGuid();
        _subscriptions.Setup(s => s.IsPremiumAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
        _repo.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember { UserId = userId, FamilySpaceId = Guid.NewGuid() });

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().CreateAsync(userId, "Santos Household", "PHP"));

        Assert.Equal("You already belong to a Family Space.", error.Message);
    }
}
