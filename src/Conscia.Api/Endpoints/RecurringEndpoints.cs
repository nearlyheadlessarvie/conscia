using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using FluentValidation;

namespace Conscia.Api.Endpoints;

public static class RecurringEndpoints
{
    public static RouteGroupBuilder MapRecurringEndpoints(this IEndpointRouteBuilder routes, ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/recurring")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Recurring");

        group.MapPost("/", async (
            HttpContext ctx,
            CreateRecurringScheduleDto dto,
            IRecurringScheduleService svc,
            IValidator<CreateRecurringScheduleDto> validator) =>
        {
            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            var userId = ctx.User.GetUserId();
            var schedule = await svc.CreateAsync(userId, dto, ctx.RequestAborted);
            return Results.Created($"/api/recurring/{schedule.Id}", RecurringScheduleResponseDto.From(schedule));
        }).WithName("CreateRecurring");

        group.MapGet("/", async (HttpContext ctx, IRecurringScheduleService svc) =>
        {
            var userId = ctx.User.GetUserId();
            var schedules = await svc.ListAsync(userId, ctx.RequestAborted);
            return Results.Ok(schedules.Select(RecurringScheduleResponseDto.From));
        }).WithName("ListRecurring");

        group.MapGet("/{id:guid}", async (HttpContext ctx, Guid id, IRecurringScheduleService svc) =>
        {
            var userId = ctx.User.GetUserId();
            var schedule = await svc.GetByIdAsync(userId, id, ctx.RequestAborted);
            return schedule is null
                ? Results.NotFound()
                : Results.Ok(RecurringScheduleResponseDto.From(schedule));
        }).WithName("GetRecurring");

        group.MapPut("/{id:guid}", async (
            HttpContext ctx,
            Guid id,
            UpdateRecurringScheduleDto dto,
            IRecurringScheduleService svc,
            IValidator<UpdateRecurringScheduleDto> validator) =>
        {
            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            var userId = ctx.User.GetUserId();
            var schedule = await svc.UpdateAsync(userId, id, dto, ctx.RequestAborted);
            return Results.Ok(RecurringScheduleResponseDto.From(schedule));
        }).WithName("UpdateRecurring");

        group.MapDelete("/{id:guid}", async (HttpContext ctx, Guid id, IRecurringScheduleService svc) =>
        {
            var userId = ctx.User.GetUserId();
            await svc.DeleteAsync(userId, id, ctx.RequestAborted);
            return Results.NoContent();
        }).WithName("DeleteRecurring");

        return group;
    }
}
