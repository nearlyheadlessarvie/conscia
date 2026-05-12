using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class FamilyMemberConfiguration : IEntityTypeConfiguration<FamilyMember>
{
    public void Configure(EntityTypeBuilder<FamilyMember> builder)
    {
        builder.ToTable("family_members");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Role)
            .HasConversion<string>()
            .IsRequired()
            .HasMaxLength(30);

        builder.HasIndex(x => x.UserId)
            .IsUnique();

        builder.HasIndex(x => new { x.FamilySpaceId, x.UserId })
            .IsUnique();
    }
}
