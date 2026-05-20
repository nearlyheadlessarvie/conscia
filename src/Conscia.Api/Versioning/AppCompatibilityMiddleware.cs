using Microsoft.Extensions.Options;

namespace Conscia.Api.Versioning;

public sealed class AppCompatibilityMiddleware
{
    private readonly RequestDelegate _next;

    public AppCompatibilityMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context, IOptions<AppCompatibilityOptions> options)
    {
        if (!context.Request.Path.StartsWithSegments("/api"))
        {
            await _next(context);
            return;
        }

        var queryVersion = context.Request.Query["v"].ToString();
        var headerVersion = context.Request.Headers["X-Api-Version"].ToString();
        var requestedApiVersion = !string.IsNullOrWhiteSpace(queryVersion)
            ? queryVersion
            : headerVersion;

        if (string.IsNullOrWhiteSpace(requestedApiVersion))
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsJsonAsync(new
            {
                code = "api_version_required",
                message = "API version is required. Use ?v=1 or X-Api-Version: 1."
            });
            return;
        }

        if (!string.Equals(requestedApiVersion, "1", StringComparison.Ordinal))
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsJsonAsync(new
            {
                code = "unsupported_api_version",
                message = "Unsupported API version. Use version 1."
            });
            return;
        }

        if (!AppVersionMetadata.TryParse(
                context.Request.Headers["X-Conscia-App-Version"],
                out var requestedVersion))
        {
            await _next(context);
            return;
        }

        if (!AppVersionMetadata.TryParse(options.Value.PreviousSupportedAppVersion, out var previousSupportedVersion) ||
            requestedVersion is null ||
            previousSupportedVersion is null)
        {
            await _next(context);
            return;
        }

        if (requestedVersion.CompareTo(previousSupportedVersion) < 0)
        {
            context.Response.StatusCode = StatusCodes.Status426UpgradeRequired;
            await context.Response.WriteAsJsonAsync(new
            {
                code = "upgrade_required",
                message = "A newer version of Conscia is required.",
                currentSupportedAppVersion = options.Value.CurrentSupportedAppVersion
            });
            return;
        }

        await _next(context);
    }
}
