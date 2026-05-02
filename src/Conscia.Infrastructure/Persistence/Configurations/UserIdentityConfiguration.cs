using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Conscia.Infrastructure.Persistence.Configurations;

public class UserIdentityConfiguration : IEntityTypeConfiguration<UserIdentity>
{
    public void Configure(EntityTypeBuilder<UserIdentity> builder)
    {
        builder.ToTable("user_identities");

        builder.HasKey(ui => ui.Id);

        builder.Property(ui => ui.Provider)
            .IsRequired()
            .HasMaxLength(20)
            .HasConversion(
                v => v.ToString(),
                v => ParseAuthProvider(v));

        builder.Property(ui => ui.ProviderSub)
            .IsRequired()
            .HasMaxLength(256);

        builder.HasOne<User>()
            .WithMany()
            .HasForeignKey(ui => ui.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(ui => new { ui.Provider, ui.ProviderSub }).IsUnique();
        builder.HasIndex(ui => ui.UserId);
    }

    private static AuthProvider ParseAuthProvider(string value)
    {
        return Enum.TryParse<AuthProvider>(value, out var result) ? result : AuthProvider.Email;
    }
}
