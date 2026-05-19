using Conscia.Api.Extensions;
using Conscia.Application.Constants;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Enums;

namespace Conscia.Api.Endpoints;

public static class CategoryEndpoints
{
    public static RouteGroupBuilder MapCategoryEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/categories")
            .RequireAuthorization()
            .WithTags("Categories");

        group.MapGet("/", async (
            HttpContext ctx,
            ICategoryService svc,
            RecordScope scope = RecordScope.Personal,
            Guid? familySpaceId = null,
            bool includeArchived = false) =>
        {
            try
            {
                var categories = await svc.ListAsync(
                    ctx.User.GetUserId(),
                    scope,
                    familySpaceId,
                    includeArchived,
                    ctx.RequestAborted);
                return Results.Ok(categories);
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
        }).WithName("ListCategories");

        group.MapPost("/", async (
            HttpContext ctx,
            CreateCategoryDto dto,
            ICategoryService svc,
            ISubscriptionService subSvc) =>
        {
            try
            {
                var userId = ctx.User.GetUserId();
                var isPremium = await subSvc.IsPremiumAsync(userId, ctx.RequestAborted);
                if (!isPremium)
                {
                    return Results.Json(
                        new
                        {
                            error = "Custom categories are a Premium feature.",
                            upgradeRequired = true
                        },
                        statusCode: StatusCodes.Status403Forbidden);
                }

                var category = await svc.CreateAsync(userId, dto, ctx.RequestAborted);
                return Results.Created($"/api/v1/categories/{category.Id}", category);
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
        }).WithName("CreateCategory");

        group.MapPut("/{id:guid}", async (
            HttpContext ctx,
            Guid id,
            UpdateCategoryDto dto,
            ICategoryService svc) =>
        {
            try
            {
                var category = await svc.UpdateAsync(ctx.User.GetUserId(), id, dto, ctx.RequestAborted);
                return Results.Ok(category);
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
            catch (KeyNotFoundException)
            {
                return Results.NotFound();
            }
        }).WithName("UpdateCategory");

        group.MapDelete("/{id:guid}", async (HttpContext ctx, Guid id, ICategoryService svc) =>
        {
            try
            {
                await svc.ArchiveAsync(ctx.User.GetUserId(), id, ctx.RequestAborted);
                return Results.NoContent();
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
            catch (KeyNotFoundException)
            {
                return Results.NotFound();
            }
        }).WithName("ArchiveCategory");

        return group;
    }
}
