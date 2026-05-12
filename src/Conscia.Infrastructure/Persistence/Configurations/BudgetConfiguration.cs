using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class BudgetConfiguration : IEntityTypeConfiguration<Budget>
{
    public void Configure(EntityTypeBuilder<Budget> builder)
    {
        builder.ToTable("budgets");

        builder.HasKey(b => b.Id);

        builder.Property(b => b.Category)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(b => b.MonthlyLimit)
            .HasPrecision(18, 2);

        builder.Property(b => b.CurrencyCode)
            .IsRequired()
            .HasMaxLength(3);

        builder.Property(b => b.Scope)
            .HasConversion<string>()
            .IsRequired()
            .HasMaxLength(20);

        builder.HasIndex(b => b.UserId);
        builder.HasIndex(b => b.FamilySpaceId);
        builder.HasIndex(b => new { b.UserId, b.Category })
            .IsUnique()
            .HasFilter("\"Scope\" = 'Personal'");
        builder.HasIndex(b => new { b.FamilySpaceId, b.Category })
            .IsUnique()
            .HasFilter("\"Scope\" = 'Family'");
    }
}
