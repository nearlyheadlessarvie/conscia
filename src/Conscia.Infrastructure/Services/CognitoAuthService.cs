using System.Security.Claims;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

/// <summary>
/// AWS Cognito auth service — production implementation.
/// Delegates to Cognito Essentials for register/login and JWKS validation for tokens.
/// Stub until Phase 7 (CDK provisions Cognito User Pool).
/// </summary>
public class CognitoAuthService : IAuthService
{
    private readonly IConfiguration _config;
    private readonly ILogger<CognitoAuthService> _logger;

    public CognitoAuthService(IConfiguration config, ILogger<CognitoAuthService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public Task<AuthResult> RegisterAsync(string email, string password, CancellationToken ct = default)
    {
        _logger.LogError("CognitoAuthService.RegisterAsync called but Cognito User Pool is not provisioned");
        return Task.FromResult(new AuthResult { Success = false, Error = "Authentication service not configured. Cognito User Pool required." });
    }

    public Task<AuthResult> LoginAsync(string email, string password, CancellationToken ct = default)
    {
        _logger.LogError("CognitoAuthService.LoginAsync called but Cognito User Pool is not provisioned");
        return Task.FromResult(new AuthResult { Success = false, Error = "Authentication service not configured. Cognito User Pool required." });
    }

    public Task<AuthResult> LoginWithGoogleAsync(string idToken, CancellationToken ct = default)
    {
        _logger.LogError("CognitoAuthService.LoginWithGoogleAsync called but Cognito Identity Pool is not provisioned");
        return Task.FromResult(new AuthResult { Success = false, Error = "Google sign-in not configured. Cognito Identity Pool required." });
    }

    public Task<AuthResult> LoginWithAppleAsync(string identityToken, string? authorizationCode, CancellationToken ct = default)
    {
        _logger.LogError("CognitoAuthService.LoginWithAppleAsync called but Cognito Identity Pool is not provisioned");
        return Task.FromResult(new AuthResult { Success = false, Error = "Apple sign-in not configured. Cognito Identity Pool required." });
    }

    public Task<ClaimsPrincipal?> ValidateTokenAsync(string token, CancellationToken ct = default)
    {
        _logger.LogError("CognitoAuthService.ValidateTokenAsync called but JWKS endpoint is not configured");
        return Task.FromResult<ClaimsPrincipal?>(null);
    }
}
