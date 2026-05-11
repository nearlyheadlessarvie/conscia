using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;

namespace Conscia.Api.Endpoints;

public static class FamilySpaceEndpoints
{
    public static RouteGroupBuilder MapFamilySpaceEndpoints(this IEndpointRouteBuilder routes)
    {
        var group = routes.MapGroup("/api/v1/family-space")
            .RequireAuthorization()
            .WithTags("Family Space");

        group.MapGet("/", async (HttpContext ctx, IFamilySpaceService svc) =>
        {
            var current = await svc.GetCurrentAsync(ctx.User.GetUserId(), ctx.RequestAborted);
            return current is null ? Results.NoContent() : Results.Ok(current);
        }).WithName("GetCurrentFamilySpace");

        group.MapGet("/overview", async (HttpContext ctx, IFamilySpaceService svc) =>
        {
            try
            {
                var overview = await svc.GetOverviewAsync(ctx.User.GetUserId(), ctx.RequestAborted);
                return Results.Ok(overview);
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
        }).WithName("GetFamilySpaceOverview");

        group.MapPost("/", async (HttpContext ctx, CreateFamilySpaceDto dto, IFamilySpaceService svc) =>
        {
            if (string.IsNullOrWhiteSpace(dto.Name))
                return Results.BadRequest(new { error = "Family Space name is required." });

            if (string.IsNullOrWhiteSpace(dto.CurrencyCode) || dto.CurrencyCode.Trim().Length != 3)
                return Results.BadRequest(new { error = "Currency code must be three letters." });

            try
            {
                var userId = ctx.User.GetUserId();
                var space = await svc.CreateAsync(userId, dto.Name, dto.CurrencyCode, ctx.RequestAborted);
                return Results.Created($"/api/v1/family-space/{space.Id}", new
                {
                    space.Id,
                    space.Name,
                    space.CurrencyCode,
                    space.IsReadOnly
                });
            }
            catch (InvalidOperationException ex) when (ex.Message.Contains("Premium", StringComparison.OrdinalIgnoreCase))
            {
                return Results.Json(new { error = ex.Message, upgradeRequired = true }, statusCode: StatusCodes.Status403Forbidden);
            }
            catch (InvalidOperationException ex)
            {
                return Results.Conflict(new { error = ex.Message });
            }
        }).WithName("CreateFamilySpace");

        group.MapPost("/invites", async (HttpContext ctx, CreateFamilyInviteDto dto, IFamilySpaceService svc) =>
        {
            try
            {
                var invite = await svc.InviteAsync(ctx.User.GetUserId(), dto.Email, dto.Role, ctx.RequestAborted);
                return Results.Created($"/api/v1/family-space/invites/{invite.Id}", new
                {
                    invite.Id,
                    invite.Email,
                    Role = invite.Role.ToString(),
                    invite.ExpiresAt
                });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
        }).WithName("CreateFamilyInvite");

        group.MapGet("/invites", async (HttpContext ctx, IFamilySpaceService svc) =>
        {
            var email = ctx.User.GetEmail();
            if (string.IsNullOrWhiteSpace(email))
                return Results.BadRequest(new { error = "Email claim is required to find Family Space invites." });

            var invites = await svc.GetPendingInvitesAsync(email, ctx.RequestAborted);
            return Results.Ok(invites);
        }).WithName("ListFamilyInvites");

        group.MapPost("/invites/{inviteId:guid}/accept", async (HttpContext ctx, Guid inviteId, IFamilySpaceService svc) =>
        {
            try
            {
                var member = await svc.AcceptInviteAsync(
                    ctx.User.GetUserId(),
                    ctx.User.GetEmail(),
                    inviteId,
                    ctx.RequestAborted);

                return Results.Ok(new
                {
                    member.Id,
                    member.FamilySpaceId,
                    Role = member.Role.ToString(),
                    member.JoinedAt
                });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
        }).WithName("AcceptFamilyInvite");

        group.MapPost("/invites/{inviteId:guid}/decline", async (HttpContext ctx, Guid inviteId, IFamilySpaceService svc) =>
        {
            try
            {
                await svc.DeclineInviteAsync(
                    ctx.User.GetUserId(),
                    ctx.User.GetEmail(),
                    inviteId,
                    ctx.RequestAborted);

                return Results.NoContent();
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
        }).WithName("DeclineFamilyInvite");

        group.MapPost("/import-preview", async (HttpContext ctx, FamilyImportPreviewRequestDto dto, IFamilySpaceService svc) =>
        {
            try
            {
                var preview = await svc.PreviewImportAsync(ctx.User.GetUserId(), dto, ctx.RequestAborted);
                return Results.Ok(preview);
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
        }).WithName("PreviewFamilyImport");

        group.MapPost("/import", async (HttpContext ctx, FamilyImportRequestDto dto, IFamilySpaceService svc) =>
        {
            try
            {
                var count = await svc.ImportAsync(ctx.User.GetUserId(), dto, ctx.RequestAborted);
                return Results.Ok(new { imported = count });
            }
            catch (UnauthorizedAccessException ex)
            {
                return Results.Json(new { error = ex.Message }, statusCode: StatusCodes.Status403Forbidden);
            }
            catch (InvalidOperationException ex)
            {
                return Results.BadRequest(new { error = ex.Message });
            }
        }).WithName("ImportFamilyRecords");

        return group;
    }
}
