using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class ExchangeRateEndpoints
{
    public static RouteGroupBuilder MapExchangeRateEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/exchange-rates")
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
