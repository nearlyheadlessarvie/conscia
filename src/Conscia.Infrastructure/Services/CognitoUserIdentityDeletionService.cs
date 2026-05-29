using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Microsoft.Extensions.Configuration;

namespace Conscia.Infrastructure.Services;

public sealed class CognitoUserIdentityDeletionService : IUserIdentityDeletionService
{
    private readonly IAmazonCognitoIdentityProvider _cognito;
    private readonly string _userPoolId;

    public CognitoUserIdentityDeletionService(
        IAmazonCognitoIdentityProvider cognito,
        IConfiguration configuration)
    {
        _cognito = cognito;
        _userPoolId = configuration["Auth:Cognito:UserPoolId"]
            ?? throw new InvalidOperationException("Auth:Cognito:UserPoolId not configured");
    }

    public async Task DeleteUserAsync(User user, CancellationToken ct = default)
    {
        var usernames = CandidateUsernames(user);
        foreach (var username in usernames)
        {
            try
            {
                await _cognito.AdminDeleteUserAsync(new AdminDeleteUserRequest
                {
                    UserPoolId = _userPoolId,
                    Username = username
                }, ct);
                return;
            }
            catch (UserNotFoundException)
            {
                // Local account cleanup should remain idempotent if Cognito was already removed.
            }
        }
    }

    private static IReadOnlyList<string> CandidateUsernames(User user)
    {
        var email = user.Email.Trim().ToLowerInvariant();
        var sub = user.Id.ToString();

        return new[] { email, sub }
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }
}
