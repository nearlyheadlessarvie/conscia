using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Domain.Constants;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Application;

public class CategoryServiceTests
{
    private readonly Mock<ICategoryRepository> _categories = new();
    private readonly Mock<IFamilySpaceRepository> _familySpaces = new();

    private CategoryService CreateService() =>
        new(
            _categories.Object,
            _familySpaces.Object,
            NullLogger<CategoryService>.Instance);

    [Fact]
    public async Task ListAsync_SeedsPersonalDefaultsWhenMissing()
    {
        var userId = Guid.NewGuid();
        _categories.Setup(r => r.ListPersonalAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Array.Empty<ManagedCategory>());
        _categories.Setup(r => r.AddAsync(It.IsAny<ManagedCategory>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((ManagedCategory category, CancellationToken _) => category);

        var result = await CreateService().ListAsync(userId, RecordScope.Personal, null);

        Assert.Contains(result, c => c.Name == "Dining" && c.Type == TransactionType.Expense.ToString());
        Assert.Contains(result, c => c.Name == "Salary" && c.Type == TransactionType.Income.ToString());
        _categories.Verify(
            r => r.AddAsync(It.Is<ManagedCategory>(c => c.Name == "Dining" && c.UserId == userId), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task CreateAsync_AddsPersonalCategoryWithNormalizedName()
    {
        var userId = Guid.NewGuid();
        _categories.Setup(r => r.GetByNormalizedNameAsync(
                userId,
                null,
                RecordScope.Personal,
                TransactionType.Expense,
                "home-repair",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((ManagedCategory?)null);
        _categories.Setup(r => r.AddAsync(It.IsAny<ManagedCategory>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((ManagedCategory category, CancellationToken _) => category);

        var result = await CreateService().CreateAsync(
            userId,
            new CreateCategoryDto("  Home Repair  ", TransactionType.Expense, RecordScope.Personal, null, "home", "blue"));

        Assert.Equal("Home Repair", result.Name);
        Assert.Equal("home-repair", result.NormalizedName);
        _categories.Verify(r => r.AddAsync(
            It.Is<ManagedCategory>(c =>
                c.UserId == userId &&
                c.Name == "Home Repair" &&
                c.NormalizedName == "home-repair" &&
                c.Scope == RecordScope.Personal),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreateAsync_DuplicateNameThrows()
    {
        var userId = Guid.NewGuid();
        _categories.Setup(r => r.GetByNormalizedNameAsync(
                userId,
                null,
                RecordScope.Personal,
                TransactionType.Expense,
                "dining",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ManagedCategory { Name = "Dining" });

        var error = await Assert.ThrowsAsync<InvalidOperationException>(() =>
            CreateService().CreateAsync(
                userId,
                new CreateCategoryDto("Dining", TransactionType.Expense, RecordScope.Personal, null, "dining", "blue")));

        Assert.Equal("A category with that name already exists.", error.Message);
    }

    [Fact]
    public async Task UpdateAsync_RenamesCategoryWhenNoDuplicateExists()
    {
        var userId = Guid.NewGuid();
        var category = new ManagedCategory
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = "Dining",
            NormalizedName = "dining",
            Type = TransactionType.Expense,
            Scope = RecordScope.Personal,
            IconKey = "dining",
            ColorKey = "blue"
        };
        _categories.Setup(r => r.GetByIdAsync(category.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(category);
        _categories.Setup(r => r.GetByNormalizedNameAsync(
                userId,
                null,
                RecordScope.Personal,
                TransactionType.Expense,
                "eating-out",
                It.IsAny<CancellationToken>()))
            .ReturnsAsync((ManagedCategory?)null);
        _categories.Setup(r => r.UpdateAsync(category, It.IsAny<CancellationToken>()))
            .ReturnsAsync(category);

        var result = await CreateService().UpdateAsync(
            userId,
            category.Id,
            new UpdateCategoryDto("Eating Out", null, "gold", null));

        Assert.Equal("Eating Out", result.Name);
        Assert.Equal("eating-out", result.NormalizedName);
        Assert.Equal("gold", result.ColorKey);
    }

    [Fact]
    public async Task ArchiveAsync_MarksCategoryArchived()
    {
        var userId = Guid.NewGuid();
        var category = new ManagedCategory
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = "Coffee",
            NormalizedName = "coffee",
            Type = TransactionType.Expense,
            Scope = RecordScope.Personal
        };
        _categories.Setup(r => r.GetByIdAsync(category.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(category);
        _categories.Setup(r => r.UpdateAsync(category, It.IsAny<CancellationToken>()))
            .ReturnsAsync(category);

        await CreateService().ArchiveAsync(userId, category.Id);

        Assert.True(category.IsArchived);
    }

    [Fact]
    public async Task CreateAsync_FamilyCategoryRequiresOwner()
    {
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        _familySpaces.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new FamilyMember
            {
                UserId = userId,
                FamilySpaceId = familySpaceId,
                Role = FamilyMemberRole.Contributor
            });

        var error = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            CreateService().CreateAsync(
                userId,
                new CreateCategoryDto("School", TransactionType.Expense, RecordScope.Family, familySpaceId, "school", "blue")));

        Assert.Equal("Only Family Space owners can manage shared categories.", error.Message);
    }

    [Fact]
    public async Task ListAsync_FamilyCategoriesRequiresMembership()
    {
        var userId = Guid.NewGuid();
        var familySpaceId = Guid.NewGuid();
        _familySpaces.Setup(r => r.GetMembershipByUserIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((FamilyMember?)null);

        var error = await Assert.ThrowsAsync<UnauthorizedAccessException>(() =>
            CreateService().ListAsync(userId, RecordScope.Family, familySpaceId));

        Assert.Equal("You do not belong to a Family Space.", error.Message);
    }
}
