using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class InsightsEndpoints
{
    public static RouteGroupBuilder MapInsightsEndpoints(this IEndpointRouteBuilder app, ApiVersionSet apiVersionSet)
    {
        var group = app.MapGroup("/api/insights")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Insights");

        group.MapGet("/behavioral", async (HttpContext ctx, IBehavioralInsightsService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var insights = await svc.GetBehavioralInsightsAsync(userId, ct);
            return insights != null ? Results.Ok(insights) : Results.NoContent();
        }).WithName("GetBehavioralInsights");

        group.MapGet("/summary", async (HttpContext ctx, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var summary = await svc.GetSummaryAsync(userId, ct);
            return summary is null ? Results.NotFound() : Results.Ok(summary);
        }).WithName("GetInsightsSummary");

        group.MapGet("/categories", async (HttpContext ctx, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var categories = await svc.GetCategoriesAsync(userId, ct);
            return Results.Ok(categories);
        }).WithName("GetInsightsCategories");

        group.MapGet("/categories/{category}", async (HttpContext ctx, string category, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var detail = await svc.GetCategoryDetailAsync(userId, category, ct);
            return detail is null ? Results.NotFound() : Results.Ok(detail);
        }).WithName("GetInsightsCategoryDetail");

        group.MapGet("/merchants", async (HttpContext ctx, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var merchants = await svc.GetMerchantsAsync(userId, ct);
            return Results.Ok(merchants);
        }).WithName("GetInsightsMerchants");

        group.MapGet("/merchants/{merchant}", async (HttpContext ctx, string merchant, IPurchasePatternService svc, CancellationToken ct) =>
        {
            var userId = ctx.User.GetUserId();
            var detail = await svc.GetMerchantDetailAsync(userId, merchant, ct);
            return detail is null ? Results.NotFound() : Results.Ok(detail);
        }).WithName("GetInsightsMerchantDetail");

        return group;
    }
}
