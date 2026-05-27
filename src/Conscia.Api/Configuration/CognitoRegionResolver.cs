using Microsoft.Extensions.Configuration;

namespace Conscia.Api.Configuration;

public static class CognitoRegionResolver
{
    public static string Resolve(IConfiguration configuration) =>
        configuration["AWS:Region"]
        ?? configuration["AWS_REGION"]
        ?? "ap-southeast-1";
}
