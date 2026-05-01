using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using FluentValidation;

namespace Conscia.Api.Endpoints;

public static class UserEndpoints
{
    public static RouteGroupBuilder MapUserEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/users")
            .RequireAuthorization()
            .WithTags("Users");

        group.MapGet("/me", async (HttpContext ctx, IUserService svc) =>
        {
            var userId = ctx.User.GetUserId();
            var user = await svc.GetByIdAsync(userId, ctx.RequestAborted);
            return user is null
                ? Results.NotFound()
                : Results.Ok(new
                {
                    user.Id,
                    user.Email,
                    user.PreferredCurrency,
                    user.Locale,
                    user.CreatedAt
                });
        }).WithName("GetCurrentUser");

        group.MapPut("/me", async (
            HttpContext ctx,
            UserProfileUpdateDto dto,
            IUserService svc,
            IValidator<UserProfileUpdateDto> validator) =>
        {
            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            var userId = ctx.User.GetUserId();
            var user = await svc.UpdateProfileAsync(userId, dto.PreferredCurrency, dto.Locale, ctx.RequestAborted);
            return Results.Ok(new
            {
                user.Id,
                user.Email,
                user.PreferredCurrency,
                user.Locale
            });
        }).WithName("UpdateCurrentUser");

        return group;
    }
}
