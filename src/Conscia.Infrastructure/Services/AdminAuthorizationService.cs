using Conscia.Application.Configuration;
using Conscia.Application.Interfaces;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Configuration;

namespace Conscia.Infrastructure.Services;

public sealed class AdminAuthorizationService : IAdminAuthorizationService
{
    private readonly IUserRepository _users;
    private readonly HashSet<string> _bootstrapEmails;

    public AdminAuthorizationService(
        IUserRepository users,
        IConfiguration configuration)
    {
        _users = users;
        _bootstrapEmails = configuration
            .GetSection(AdminBootstrapOptions.SectionName)
            .GetSection("Emails")
            .GetChildren()
            .Select(child => child.Value?.Trim().ToLowerInvariant())
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Cast<string>()
            .ToHashSet(StringComparer.Ordinal);
    }

    public async Task<bool> IsAuthorizedAsync(Guid userId, string email, CancellationToken ct = default)
    {
        var identities = await _users.GetIdentitiesByUserAsync(userId, ct);
        var adminIdentity = identities.FirstOrDefault(identity => identity.Role == UserIdentityRole.Admin);
        if (adminIdentity is not null)
        {
            return true;
        }

        var normalizedEmail = email.Trim().ToLowerInvariant();
        if (!_bootstrapEmails.Contains(normalizedEmail))
        {
            return false;
        }

        var bootstrapIdentity = identities.FirstOrDefault(identity =>
            identity.Provider == AuthProvider.Email &&
            string.Equals(identity.ProviderSub, normalizedEmail, StringComparison.OrdinalIgnoreCase));

        if (bootstrapIdentity is null)
        {
            return false;
        }

        bootstrapIdentity.Role = UserIdentityRole.Admin;
        await _users.UpdateIdentityAsync(bootstrapIdentity, ct);
        return true;
    }
}
