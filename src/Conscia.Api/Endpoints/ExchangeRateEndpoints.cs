using Asp.Versioning.Builder;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class ExchangeRateEndpoints
{
    public static RouteGroupBuilder MapExchangeRateEndpoints(this IEndpointRouteBuilder app, ApiVersionSet apiVersionSet)
    {
        var group = app.MapGroup("/api/exchange-rates")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("ExchangeRates");

        group.MapGet("/{from}/{to}", async (string from, string to, IExchangeRateService svc, CancellationToken ct) =>
        {
            var rate = await svc.GetRateAsync(from, to, ct);
            return rate is null
                ? Results.NotFound(new { error = $"Rate unavailable for {from.ToUpper()}/{to.ToUpper()}" })
                : Results.Ok(new { from = from.ToUpper(), to = to.ToUpper(), rate });
        });

        return group;
    }
}
