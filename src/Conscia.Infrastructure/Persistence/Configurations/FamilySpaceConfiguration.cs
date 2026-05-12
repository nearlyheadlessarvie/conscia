using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class FamilySpaceConfiguration : IEntityTypeConfiguration<FamilySpace>
{
    public void Configure(EntityTypeBuilder<FamilySpace> builder)
    {
        builder.ToTable("family_spaces");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Name)
            .IsRequired()
            .HasMaxLength(120);

        builder.Property(x => x.CurrencyCode)
            .IsRequired()
            .HasMaxLength(3);

        builder.Property(x => x.IsReadOnly)
            .HasDefaultValue(false);

        builder.HasIndex(x => x.CreatedByUserId);
    }
}
