using System.Diagnostics;

namespace Conscia.Api.Middleware;

public class ColdStartMiddleware
{
    private static bool _isColdStart = true;
    private readonly RequestDelegate _next;

    public ColdStartMiddleware(RequestDelegate next) => _next = next;

    public async Task InvokeAsync(HttpContext context)
    {
        if (_isColdStart)
        {
            _isColdStart = false;
            Activity.Current?.SetTag("lambda.cold_start", true);
            context.Response.Headers.Append("X-Cold-Start", "true");
        }
        await _next(context);
    }
}
