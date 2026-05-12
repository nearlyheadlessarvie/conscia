using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class ManagedCategoryConfiguration : IEntityTypeConfiguration<ManagedCategory>
{
    public void Configure(EntityTypeBuilder<ManagedCategory> builder)
    {
        builder.ToTable("managed_categories");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.Name)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(c => c.NormalizedName)
            .IsRequired()
            .HasMaxLength(120);

        builder.Property(c => c.Type)
            .HasConversion<string>()
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(c => c.Scope)
            .HasConversion<string>()
            .IsRequired()
            .HasMaxLength(20);

        builder.Property(c => c.IconKey)
            .IsRequired()
            .HasMaxLength(40);

        builder.Property(c => c.ColorKey)
            .IsRequired()
            .HasMaxLength(40);

        builder.HasIndex(c => c.UserId);
        builder.HasIndex(c => c.FamilySpaceId);
        builder.HasIndex(c => new { c.UserId, c.Scope, c.Type, c.NormalizedName });
        builder.HasIndex(c => new { c.FamilySpaceId, c.Type, c.NormalizedName });
    }
}
