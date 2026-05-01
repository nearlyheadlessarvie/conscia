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
        // Will be implemented when CDK provisions the Cognito User Pool
        _logger.LogWarning("CognitoAuthService.RegisterAsync not yet implemented — use MockAuthService for development");
        throw new NotImplementedException("Cognito registration requires User Pool provisioned via CDK");
    }

    public Task<AuthResult> LoginAsync(string email, string password, CancellationToken ct = default)
    {
        _logger.LogWarning("CognitoAuthService.LoginAsync not yet implemented — use MockAuthService for development");
        throw new NotImplementedException("Cognito login requires User Pool provisioned via CDK");
    }

    public Task<ClaimsPrincipal?> ValidateTokenAsync(string token, CancellationToken ct = default)
    {
        // In production, ASP.NET JWT Bearer middleware handles validation against Cognito JWKS endpoint.
        // This method exists for explicit validation in non-middleware contexts.
        _logger.LogWarning("CognitoAuthService.ValidateTokenAsync — use JWT Bearer middleware for standard flows");
        throw new NotImplementedException("Cognito token validation requires JWKS endpoint from CDK");
    }
}
