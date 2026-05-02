using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Repositories;

namespace Conscia.Tests.Unit.Infrastructure;

public class UserRepositoryTests : EfCoreTestBase
{
    private readonly UserRepository _repo;

    public UserRepositoryTests() => _repo = new UserRepository(Db);

    [Fact]
    public async Task Add_CreatesUser()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "test@example.com",
            PreferredCurrency = "USD",
            Locale = "en-US"
        };

        var result = await _repo.AddAsync(user);

        Assert.Equal(user.Id, result.Id);
        Assert.Equal("test@example.com", result.Email);
    }

    [Fact]
    public async Task GetById_ExistingUser_ReturnsUser()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "find@test.com" };
        await _repo.AddAsync(user);

        var found = await _repo.GetByIdAsync(user.Id);

        Assert.NotNull(found);
        Assert.Equal(user.Email, found.Email);
    }

    [Fact]
    public async Task GetById_NonExistent_ReturnsNull()
    {
        var found = await _repo.GetByIdAsync(Guid.NewGuid());
        Assert.Null(found);
    }

    [Fact]
    public async Task GetByProvider_ReturnsCorrectUser()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "provider@test.com" };
        await _repo.AddAsync(user);
        await _repo.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Email,
            ProviderSub = "sub_unique"
        });

        var found = await _repo.GetByProviderAsync(AuthProvider.Email, "sub_unique");

        Assert.NotNull(found);
        Assert.Equal(user.Id, found.Id);
    }

    [Fact]
    public async Task GetByProvider_WrongProvider_ReturnsNull()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "wrong@test.com" };
        await _repo.AddAsync(user);
        await _repo.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Email,
            ProviderSub = "sub_email_only"
        });

        var found = await _repo.GetByProviderAsync(AuthProvider.Google, "sub_email_only");

        Assert.Null(found);
    }

    [Fact]
    public async Task GetByEmail_ReturnsCorrectUser()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "email@test.com" };
        await _repo.AddAsync(user);

        var found = await _repo.GetByEmailAsync("email@test.com");

        Assert.NotNull(found);
        Assert.Equal(user.Id, found.Id);
    }

    [Fact]
    public async Task AddIdentity_CreatesIdentityRow()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "identity@test.com" };
        await _repo.AddAsync(user);

        var identity = new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Google,
            ProviderSub = "google_123"
        };
        var result = await _repo.AddIdentityAsync(identity);

        Assert.Equal(identity.Id, result.Id);
        Assert.Equal(AuthProvider.Google, result.Provider);

        var found = await _repo.GetByProviderAsync(AuthProvider.Google, "google_123");
        Assert.NotNull(found);
        Assert.Equal(user.Id, found.Id);
    }

    [Fact]
    public async Task Update_ModifiesUser()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "update@test.com" };
        await _repo.AddAsync(user);

        user.PreferredCurrency = "EUR";
        await _repo.UpdateAsync(user);

        var found = await _repo.GetByIdAsync(user.Id);
        Assert.Equal("EUR", found!.PreferredCurrency);
    }

    [Fact]
    public async Task Delete_RemovesUser()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "delete@test.com" };
        await _repo.AddAsync(user);

        await _repo.DeleteAsync(user.Id);

        var found = await _repo.GetByIdAsync(user.Id);
        Assert.Null(found);
    }

    [Fact]
    public async Task Delete_NonExistent_DoesNotThrow()
    {
        await _repo.DeleteAsync(Guid.NewGuid());
    }
}
