using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class SuggestionEndpoints
{
    public static RouteGroupBuilder MapSuggestionEndpoints(this IEndpointRouteBuilder app, ApiVersionSet apiVersionSet)
    {
        var group = app.MapGroup("/api/suggestions")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Suggestions");

        group.MapGet("/purchases", GetPurchaseSuggestions)
            .WithName("GetPurchaseSuggestions")
            .WithDescription("Get purchase suggestions for the user")
            .Produces<IReadOnlyList<PurchaseSuggestionDto>>(StatusCodes.Status200OK)
            .Produces(StatusCodes.Status500InternalServerError);

        return group;
    }

    private static async Task<IResult> GetPurchaseSuggestions(
        HttpContext ctx,
        IPurchaseSuggestionService svc,
        CancellationToken ct)
    {
        var userId = ctx.User.GetUserId();
        var suggestions = await svc.GetSuggestionsAsync(userId, ct);
        return Results.Ok(suggestions);
    }
}
