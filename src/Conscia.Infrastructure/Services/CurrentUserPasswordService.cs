using System.Security.Claims;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Configuration;

namespace Conscia.Infrastructure.Services;

public sealed class CurrentUserPasswordService : ICurrentUserPasswordService
{
    private readonly IAmazonCognitoIdentityProvider _cognito;
    private readonly IUserRepository _users;
    private readonly string _userPoolId;

    public CurrentUserPasswordService(
        IAmazonCognitoIdentityProvider cognito,
        IUserRepository users,
        IConfiguration configuration)
    {
        _cognito = cognito;
        _users = users;
        _userPoolId = configuration["Auth:Cognito:UserPoolId"]
            ?? throw new InvalidOperationException("Auth:Cognito:UserPoolId not configured");
    }

    public async Task SetPasswordAsync(
        ClaimsPrincipal principal,
        string password,
        string? currentPassword = null,
        string? accessToken = null,
        CancellationToken ct = default)
    {
        var username = principal.FindFirst("cognito:username")?.Value
            ?? principal.FindFirst("username")?.Value
            ?? principal.FindFirst(ClaimTypes.Email)?.Value
            ?? principal.FindFirst("email")?.Value;
        if (string.IsNullOrWhiteSpace(username))
        {
            throw new InvalidOperationException("Authenticated user is missing a Cognito username.");
        }

        var email = principal.FindFirst(ClaimTypes.Email)?.Value
            ?? principal.FindFirst("email")?.Value;
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new InvalidOperationException("Authenticated user is missing an email.");
        }

        email = NormalizeEmail(email);
        var identity = await GetEmailIdentityAsync(email, ct);
        if (identity?.HasPassword == true)
        {
            if (string.IsNullOrWhiteSpace(currentPassword))
            {
                throw new InvalidOperationException("Current password is required.");
            }

            if (string.IsNullOrWhiteSpace(accessToken))
            {
                throw new InvalidOperationException("Current session token is required.");
            }

            await ChangeExistingPasswordAsync(accessToken, currentPassword, password, ct);
        }
        else
        {
            await SetInitialPasswordAsync(username, password, ct);
        }

        await MarkEmailIdentityHasPasswordAsync(email, identity, ct);
    }

    private async Task ChangeExistingPasswordAsync(
        string accessToken,
        string currentPassword,
        string password,
        CancellationToken ct)
    {
        try
        {
            await _cognito.ChangePasswordAsync(new ChangePasswordRequest
            {
                AccessToken = accessToken,
                PreviousPassword = currentPassword,
                ProposedPassword = password
            }, ct);
        }
        catch (NotAuthorizedException ex)
        {
            throw new InvalidOperationException("Current password is incorrect.", ex);
        }
        catch (InvalidPasswordException ex)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    private async Task SetInitialPasswordAsync(string username, string password, CancellationToken ct)
    {
        try
        {
            await _cognito.AdminSetUserPasswordAsync(new AdminSetUserPasswordRequest
            {
                UserPoolId = _userPoolId,
                Username = username,
                Password = password,
                Permanent = true
            }, ct);
        }
        catch (InvalidPasswordException ex)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }
    }

    private async Task<UserIdentity?> GetEmailIdentityAsync(string email, CancellationToken ct)
    {
        var user = await _users.GetByEmailAsync(email, ct);
        if (user is null)
        {
            return null;
        }

        var identities = await _users.GetIdentitiesByUserAsync(user.Id, ct);
        return identities.FirstOrDefault(identity =>
            identity.Provider == AuthProvider.Email &&
            string.Equals(identity.ProviderSub, email, StringComparison.OrdinalIgnoreCase));
    }

    private async Task MarkEmailIdentityHasPasswordAsync(
        string email,
        UserIdentity? identity,
        CancellationToken ct)
    {
        if (identity is not null)
        {
            if (!identity.HasPassword)
            {
                identity.HasPassword = true;
                await _users.UpdateIdentityAsync(identity, ct);
            }

            return;
        }

        var user = await _users.GetByEmailAsync(email, ct);
        if (user is null)
        {
            return;
        }

        await _users.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            Provider = AuthProvider.Email,
            ProviderSub = email,
            HasPassword = true
        }, ct);
    }

    private static string NormalizeEmail(string email) => email.Trim().ToLowerInvariant();
}
