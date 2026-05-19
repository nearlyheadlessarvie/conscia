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
    private readonly Mock<ITransactionRepository> _transactionRepoMock = new();
    private readonly UserService _svc;

    public UserServiceTests()
    {
        _transactionRepoMock
            .Setup(r => r.QueryByUserAsync(
                It.IsAny<Guid>(),
                It.IsAny<DateTime?>(),
                It.IsAny<DateTime?>(),
                It.IsAny<string?>(),
                It.IsAny<int>(),
                It.IsAny<string?>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((Array.Empty<Transaction>(), null));
        _svc = new UserService(_repoMock.Object, _transactionRepoMock.Object);
    }

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
    public async Task UpdateProfileAsync_RejectsCurrencyChange_WhenTransactionsExist()
    {
        var id = Guid.NewGuid();
        var user = new User { Id = id, PreferredCurrency = "USD", Locale = "en-US" };
        _repoMock.Setup(r => r.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(user);
        _transactionRepoMock
            .Setup(r => r.QueryByUserAsync(
                id,
                null,
                null,
                null,
                1,
                null,
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((
                new[]
                {
                    new Transaction
                    {
                        Id = Guid.NewGuid(),
                        UserId = id,
                        Type = TransactionType.Expense,
                        Amount = new(10m, "USD"),
                        Category = "Dining",
                        Date = DateTime.UtcNow,
                    },
                },
                null));

        var ex = await Assert.ThrowsAsync<InvalidOperationException>(
            () => _svc.UpdateProfileAsync(
                id,
                new UserProfileUpdateDto { PreferredCurrency = "EUR" }));

        Assert.Equal(
            "Default currency is locked after your first transaction.",
            ex.Message);
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
    public async Task UpdateProfileAsync_UpdatesDisplayNameAndProfilePictureKey()
    {
        var id = Guid.NewGuid();
        var user = new User { Id = id, Email = "story@example.com" };
        _repoMock.Setup(r => r.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(user);
        _repoMock.Setup(r => r.UpdateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User u, CancellationToken _) => u);

        var result = await _svc.UpdateProfileAsync(
            id,
            new UserProfileUpdateDto
            {
                DisplayName = "Story Demo",
                ProfilePictureKey = $"profile-pictures/{id}/avatar.jpg"
            });

        Assert.Equal("Story Demo", result.DisplayName);
        Assert.Equal($"profile-pictures/{id}/avatar.jpg", result.ProfilePictureKey);
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
    public async Task UpdateProfileAsync_UpdatesLocationSuggestionsEnabled()
    {
        var id = Guid.NewGuid();
        var user = new User { Id = id, LocationSuggestionsEnabled = false };
        _repoMock.Setup(r => r.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(user);
        _repoMock.Setup(r => r.UpdateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User u, CancellationToken _) => u);

        var result = await _svc.UpdateProfileAsync(
            id,
            new UserProfileUpdateDto { LocationSuggestionsEnabled = true });

        Assert.True(result.LocationSuggestionsEnabled);
    }

    [Fact]
    public async Task UpdateProfileAsync_UpdatesAiPersonalityIntensity()
    {
        var id = Guid.NewGuid();
        var user = new User { Id = id, AiPersonalityIntensity = "balanced" };
        _repoMock.Setup(r => r.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(user);
        _repoMock.Setup(r => r.UpdateAsync(It.IsAny<User>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((User u, CancellationToken _) => u);

        var result = await _svc.UpdateProfileAsync(
            id,
            new UserProfileUpdateDto { AiPersonalityIntensity = "intense" });

        Assert.Equal("intense", result.AiPersonalityIntensity);
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
