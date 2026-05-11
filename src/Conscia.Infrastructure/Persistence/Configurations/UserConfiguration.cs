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

        builder.Property(u => u.EmailConfirmed)
            .HasDefaultValue(true);

        builder.Property(u => u.PreferredCurrency)
            .IsRequired()
            .HasMaxLength(3);

        builder.Property(u => u.Locale)
            .IsRequired()
            .HasMaxLength(10);

        builder.Property(u => u.SpendingPersonality).HasMaxLength(50);
        builder.Property(u => u.IncomeRange).HasMaxLength(50);
        builder.Property(u => u.OccupationType).HasMaxLength(50);
        builder.Property(u => u.HouseholdSize).HasMaxLength(50);
        builder.Property(u => u.HasCompletedOnboarding)
            .HasDefaultValue(false);
        builder.Property(u => u.LocationSuggestionsEnabled)
            .HasDefaultValue(false);
        builder.Property(u => u.AiPersonalityIntensity)
            .IsRequired()
            .HasMaxLength(20)
            .HasDefaultValue("balanced");

        builder.HasIndex(u => u.Email).IsUnique();
    }
}
