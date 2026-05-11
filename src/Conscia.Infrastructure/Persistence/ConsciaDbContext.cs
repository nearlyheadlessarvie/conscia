using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace Conscia.Infrastructure.Persistence;

public class ConsciaDbContext : DbContext
{
    public ConsciaDbContext(DbContextOptions<ConsciaDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<UserIdentity> UserIdentities => Set<UserIdentity>();
    public DbSet<UserSubscription> UserSubscriptions => Set<UserSubscription>();
    public DbSet<FamilySpace> FamilySpaces => Set<FamilySpace>();
    public DbSet<FamilyMember> FamilyMembers => Set<FamilyMember>();
    public DbSet<FamilyInvite> FamilyInvites => Set<FamilyInvite>();
    public DbSet<Budget> Budgets => Set<Budget>();
    public DbSet<Receipt> Receipts => Set<Receipt>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ConsciaDbContext).Assembly);
    }
}
