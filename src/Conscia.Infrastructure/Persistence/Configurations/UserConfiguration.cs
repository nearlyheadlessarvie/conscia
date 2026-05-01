using Conscia.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");

        builder.HasKey(u => u.Id);

        builder.Property(u => u.Email)
            .IsRequired()
            .HasMaxLength(256);

        builder.Property(u => u.CognitoSub)
            .IsRequired()
            .HasMaxLength(128);

        builder.Property(u => u.PreferredCurrency)
            .IsRequired()
            .HasMaxLength(3);

        builder.Property(u => u.Locale)
            .IsRequired()
            .HasMaxLength(10);

        builder.HasIndex(u => u.Email).IsUnique();
        builder.HasIndex(u => u.CognitoSub).IsUnique();
    }
}
