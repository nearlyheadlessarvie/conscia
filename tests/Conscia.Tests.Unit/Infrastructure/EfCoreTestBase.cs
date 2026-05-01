using Conscia.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Tests.Unit.Infrastructure;

public abstract class EfCoreTestBase : IDisposable
{
    protected readonly ConsciaDbContext Db;

    protected EfCoreTestBase()
    {
        var options = new DbContextOptionsBuilder<ConsciaDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;

        Db = new ConsciaDbContext(options);
    }

    public void Dispose()
    {
        Db.Dispose();
        GC.SuppressFinalize(this);
    }
}
