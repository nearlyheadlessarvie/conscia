using Microsoft.Extensions.Configuration;

namespace Conscia.Api.Configuration;

public static class CognitoRegionResolver
{
    public static string Resolve(IConfiguration configuration) =>
        configuration["AWS:Region"]
        ?? configuration["AWS_REGION"]
        ?? "ap-southeast-1";

    public static string ResolveIssuer(IConfiguration configuration)
    {
        var region = Resolve(configuration);
        var userPoolId = configuration["Auth:Cognito:UserPoolId"]
            ?? throw new InvalidOperationException("Auth:Cognito:UserPoolId is required.");

        return $"https://cognito-idp.{region}.amazonaws.com/{userPoolId}";
    }
}
