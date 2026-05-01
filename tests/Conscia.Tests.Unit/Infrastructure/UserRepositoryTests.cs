using Conscia.Domain.Entities;
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
            CognitoSub = "sub_123",
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
        var user = new User { Id = Guid.NewGuid(), Email = "find@test.com", CognitoSub = "sub_find" };
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
    public async Task GetByCognitoSub_ReturnsCorrectUser()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "cognito@test.com", CognitoSub = "sub_unique" };
        await _repo.AddAsync(user);

        var found = await _repo.GetByCognitoSubAsync("sub_unique");

        Assert.NotNull(found);
        Assert.Equal(user.Id, found.Id);
    }

    [Fact]
    public async Task GetByEmail_ReturnsCorrectUser()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "email@test.com", CognitoSub = "sub_email" };
        await _repo.AddAsync(user);

        var found = await _repo.GetByEmailAsync("email@test.com");

        Assert.NotNull(found);
        Assert.Equal(user.Id, found.Id);
    }

    [Fact]
    public async Task Update_ModifiesUser()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "update@test.com", CognitoSub = "sub_up" };
        await _repo.AddAsync(user);

        user.PreferredCurrency = "EUR";
        await _repo.UpdateAsync(user);

        var found = await _repo.GetByIdAsync(user.Id);
        Assert.Equal("EUR", found!.PreferredCurrency);
    }

    [Fact]
    public async Task Delete_RemovesUser()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "delete@test.com", CognitoSub = "sub_del" };
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
