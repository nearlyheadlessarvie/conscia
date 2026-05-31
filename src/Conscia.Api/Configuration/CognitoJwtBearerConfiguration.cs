using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace Conscia.Api.Configuration;

public static class CognitoJwtBearerConfiguration
{
    private const string AccessTokenUse = "access";
    private const string IdTokenUse = "id";

    public static TokenValidationParameters CreateTokenValidationParameters(IConfiguration configuration)
    {
        var issuer = CognitoRegionResolver.ResolveIssuer(configuration);
        var clientId = configuration["Auth:Cognito:ClientId"]
            ?? throw new InvalidOperationException("Auth:Cognito:ClientId is required.");

        return new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = issuer,
            ValidateAudience = true,
            ValidAudience = clientId,
            AudienceValidator = (audiences, token, _) => HasExpectedClient(audiences, token, clientId)
        };
    }

    public static bool HasAcceptedTokenUse(ClaimsPrincipal? principal)
    {
        var tokenUse = principal?.FindFirst("token_use")?.Value;
        return string.Equals(tokenUse, AccessTokenUse, StringComparison.Ordinal) ||
            string.Equals(tokenUse, IdTokenUse, StringComparison.Ordinal);
    }

    private static bool HasExpectedClient(
        IEnumerable<string> audiences,
        SecurityToken token,
        string clientId)
    {
        return audiences.Any(audience => string.Equals(audience, clientId, StringComparison.Ordinal)) ||
            HasExpectedClientIdClaim(token, clientId);
    }

    private static bool HasExpectedClientIdClaim(SecurityToken token, string clientId)
    {
        return token switch
        {
            JwtSecurityToken jwt => HasClaim(jwt.Claims, "client_id", clientId),
            JsonWebToken jsonWebToken => HasClaim(jsonWebToken.Claims, "client_id", clientId),
            _ => false
        };
    }

    private static bool HasClaim(IEnumerable<Claim> claims, string type, string value) =>
        claims.Any(claim =>
            string.Equals(claim.Type, type, StringComparison.Ordinal) &&
            string.Equals(claim.Value, value, StringComparison.Ordinal));
}
