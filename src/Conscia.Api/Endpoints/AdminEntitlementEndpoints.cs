using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class AdminEntitlementEndpoints
{
    public static RouteGroupBuilder MapAdminEntitlementEndpoints(this IEndpointRouteBuilder routes, ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/admin")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Admin");

        group.MapGet("/users/by-email", async (
            HttpContext ctx,
            string email,
            IAdminAuthorizationService authz,
            ISubscriptionAdminService service) =>
        {
            if (!await authz.IsAuthorizedAsync(ctx.User.GetUserId(), ctx.User.GetEmail(), ctx.RequestAborted))
            {
                return Results.Forbid();
            }

            var result = await service.LookupByEmailAsync(email, ctx.RequestAborted);
            return result is null ? Results.NotFound() : Results.Ok(result);
        });

        group.MapPut("/entitlements/premium-lifetime/{userId:guid}", async (
            HttpContext ctx,
            Guid userId,
            GrantLifetimePremiumRequest request,
            IAdminAuthorizationService authz,
            ISubscriptionAdminService service) =>
        {
            if (!await authz.IsAuthorizedAsync(ctx.User.GetUserId(), ctx.User.GetEmail(), ctx.RequestAborted))
            {
                return Results.Forbid();
            }

            var result = await service.GrantLifetimePremiumAsync(userId, request.GrantedBy, request.Note, ctx.RequestAborted);
            return Results.Ok(result);
        });

        group.MapDelete("/entitlements/premium-lifetime/{userId:guid}", async (
            HttpContext ctx,
            Guid userId,
            IAdminAuthorizationService authz,
            ISubscriptionAdminService service) =>
        {
            if (!await authz.IsAuthorizedAsync(ctx.User.GetUserId(), ctx.User.GetEmail(), ctx.RequestAborted))
            {
                return Results.Forbid();
            }

            var result = await service.RevokeLifetimePremiumAsync(userId, ctx.RequestAborted);
            return result is null ? Results.NotFound() : Results.Ok(result);
        });

        group.MapPost("/reviewer-accounts", async (
            HttpContext ctx,
            ProvisionReviewerAccountRequest request,
            IAdminAuthorizationService authz,
            IUserProvisioningService service) =>
        {
            if (!await authz.IsAuthorizedAsync(ctx.User.GetUserId(), ctx.User.GetEmail(), ctx.RequestAborted))
            {
                return Results.Forbid();
            }

            var result = await service.ProvisionReviewerAsync(request, ctx.RequestAborted);
            return Results.Ok(result);
        });

        return group;
    }
}
