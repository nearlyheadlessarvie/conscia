using Conscia.Domain.Entities;
using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Tests.Unit.Infrastructure;

public class BudgetModelConfigurationTests
{
    [Fact]
    public void BudgetUniqueIndexes_AreScopedForPersonalAndFamilyBudgets()
    {
        var options = new DbContextOptionsBuilder<ConsciaDbContext>()
            .UseInMemoryDatabase(Guid.NewGuid().ToString())
            .Options;

        using var db = new ConsciaDbContext(options);

        var indexes = db.Model
            .FindEntityType(typeof(Budget))!
            .GetIndexes()
            .Where(index => index.IsUnique)
            .Select(index => new
            {
                Properties = index.Properties.Select(p => p.Name).ToArray(),
                Filter = index.GetFilter()
            })
            .ToList();

        Assert.Contains(
            indexes,
            index =>
                index.Properties.SequenceEqual(["UserId", "Category"]) &&
                index.Filter == "\"Scope\" = 'Personal'");

        Assert.Contains(
            indexes,
            index =>
                index.Properties.SequenceEqual(["FamilySpaceId", "Category"]) &&
                index.Filter == "\"Scope\" = 'Family'");
    }
}
