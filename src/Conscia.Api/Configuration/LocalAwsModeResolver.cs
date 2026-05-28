using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

namespace Conscia.Api.Configuration;

public static class LocalAwsModeResolver
{
    public static bool ShouldUseLocalAwsEmulators(
        IConfiguration configuration,
        IHostEnvironment environment)
    {
        return environment.IsDevelopment() &&
            !configuration.GetValue<bool>("LocalAws:UseRealAws");
    }
}
