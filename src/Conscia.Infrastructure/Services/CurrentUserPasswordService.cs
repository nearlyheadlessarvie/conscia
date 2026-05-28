using System.Security.Claims;
using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Configuration;

namespace Conscia.Infrastructure.Services;

public sealed class CurrentUserPasswordService : ICurrentUserPasswordService
{
    private readonly IAmazonCognitoIdentityProvider _cognito;
    private readonly string _userPoolId;

    public CurrentUserPasswordService(
        IAmazonCognitoIdentityProvider cognito,
        IConfiguration configuration)
    {
        _cognito = cognito;
        _userPoolId = configuration["Auth:Cognito:UserPoolId"]
            ?? throw new InvalidOperationException("Auth:Cognito:UserPoolId not configured");
    }

    public async Task SetPasswordAsync(
        ClaimsPrincipal principal,
        string password,
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
}
