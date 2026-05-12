using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class FamilyInviteConfiguration : IEntityTypeConfiguration<FamilyInvite>
{
    public void Configure(EntityTypeBuilder<FamilyInvite> builder)
    {
        builder.ToTable("family_invites");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Email)
            .IsRequired()
            .HasMaxLength(256);

        builder.Property(x => x.Role)
            .HasConversion<string>()
            .IsRequired()
            .HasMaxLength(30);

        builder.HasIndex(x => new { x.FamilySpaceId, x.Email });
        builder.HasIndex(x => x.Email);
    }
}
