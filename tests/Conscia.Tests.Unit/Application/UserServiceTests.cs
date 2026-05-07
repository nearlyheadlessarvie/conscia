using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class UserServiceTests
{
    private readonly Mock<IUserRepository> _repoMock = new();
    private readonly UserService _svc;

    public UserServiceTests() => _svc = new UserService(_repoMock.Object);

    [Fact]
    public async Task GetByIdAsync_ReturnsUser()
    {
        var id = Guid.NewGuid();
        var user = new User { Id = id, Email = "test@example.com" };
        _repoMock.Setup(r => r.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(user);

        var result = await _svc.GetByIdAsync(id);

        Assert.NotNull(result);
        Assert.Equal(id, result!.Id);
    }

    [Fact]
    public async Task GetByIdAsync_ReturnsNull_WhenNotFound()
    {
        _repoMock.Setup(r => r.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);

        var result = await _svc.GetByIdAsync(Guid.NewGuid());

        Assert.Null(result);
    }

    [Fact]
    public async Task GetByProviderAsync_DelegatesToRepo()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "provider@test.com" };
        _repoMock.Setup(r => r.GetByProviderAsync(AuthProvider.Google, "google_123", It.IsAny<CancellationToken>()))
            .ReturnsAsync(user);

        var result = await _svc.GetByProviderAsync(AuthProvider.Google, "google_123");

        Assert.NotNull(result);
        Assert.Equal(user.Id, result!.Id);
    }

    [Fact]
    public async Task UpdateProfileAsync_UpdatesCurrency()
    {
        var id = Guid.NewGuid();
        var user = new User { Id = id, PreferredCurrency = "USD", Locale = "en-US" };
        _repoMock.Setup(r => r.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(user);
        _repoMock.Setup(r => r.UpdateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User u, CancellationToken _) => u);

        var result = await _svc.UpdateProfileAsync(id, new UserProfileUpdateDto { PreferredCurrency = "EUR" });

        Assert.Equal("EUR", result.PreferredCurrency);
        Assert.Equal("en-US", result.Locale);
    }

    [Fact]
    public async Task UpdateProfileAsync_UpdatesLocale()
    {
        var id = Guid.NewGuid();
        var user = new User { Id = id, PreferredCurrency = "USD", Locale = "en-US" };
        _repoMock.Setup(r => r.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(user);
        _repoMock.Setup(r => r.UpdateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User u, CancellationToken _) => u);

        var result = await _svc.UpdateProfileAsync(id, new UserProfileUpdateDto { Locale = "es-MX" });

        Assert.Equal("USD", result.PreferredCurrency);
        Assert.Equal("es-MX", result.Locale);
    }

    [Fact]
    public async Task UpdateProfileAsync_UpdatesOnboardingCompletion()
    {
        var id = Guid.NewGuid();
        var user = new User { Id = id, HasCompletedOnboarding = false };
        _repoMock.Setup(r => r.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(user);
        _repoMock.Setup(r => r.UpdateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User u, CancellationToken _) => u);

        var result = await _svc.UpdateProfileAsync(
            id,
            new UserProfileUpdateDto { HasCompletedOnboarding = true });

        Assert.True(result.HasCompletedOnboarding);
    }

    [Fact]
    public async Task UpdateProfileAsync_ThrowsKeyNotFound_WhenUserMissing()
    {
        _repoMock.Setup(r => r.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User?)null);

        await Assert.ThrowsAsync<KeyNotFoundException>(
            () => _svc.UpdateProfileAsync(Guid.NewGuid(), new UserProfileUpdateDto { PreferredCurrency = "EUR" }));
    }
}
