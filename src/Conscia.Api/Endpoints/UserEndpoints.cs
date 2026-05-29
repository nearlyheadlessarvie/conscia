using Asp.Versioning.Builder;
using Conscia.Api.Extensions;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using FluentValidation;

namespace Conscia.Api.Endpoints;

public static class UserEndpoints
{
    public static RouteGroupBuilder MapUserEndpoints(this IEndpointRouteBuilder routes, ApiVersionSet apiVersionSet)
    {
        var group = routes.MapGroup("/api/users")
            .WithApiVersionSet(apiVersionSet)
            .MapToApiVersion(1.0)
            .RequireAuthorization()
            .WithTags("Users");

        group.MapGet("/me", async (
            HttpContext ctx,
            IUserService svc,
            IUserRepository users,
            IS3StorageService storage) =>
        {
            var userId = ctx.User.GetUserId();
            var user = await svc.GetByIdAsync(userId, ctx.RequestAborted);
            return user is null
                ? Results.NotFound()
                : Results.Ok(await ToProfileResponseAsync(
                    user,
                    users,
                    storage,
                    ctx.RequestAborted));
        }).WithName("GetCurrentUser");

        group.MapPost("/me/profile-picture-upload-url", async (
            HttpContext ctx,
            ProfilePictureUploadRequestDto dto,
            IS3StorageService storage,
            IConfiguration config) =>
        {
            var normalizedContentType = dto.ContentType.Trim().ToLowerInvariant();
            if (!TryGetProfilePictureExtension(normalizedContentType, out var extension))
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    ["contentType"] =
                    [
                        "Profile picture must be a JPEG, PNG, or WebP image"
                    ]
                });
            }

            var userId = ctx.User.GetUserId();
            var key = $"profile-pictures/{userId}/{Guid.NewGuid():N}{extension}";
            var uploadUrl = await storage.GeneratePresignedUploadUrlAsync(
                key,
                normalizedContentType,
                15,
                ctx.RequestAborted);

            var useProxyUpload = bool.TryParse(
                config["AWS:S3:UseApiProxyUploads"],
                out var configuredUseProxyUpload) && configuredUseProxyUpload;

            return Results.Ok(new ProfilePictureUploadResponseDto
            {
                UploadUrl = uploadUrl,
                ProxyUploadUrl = useProxyUpload
                    ? $"users/me/profile-picture-upload?key={Uri.EscapeDataString(key)}"
                    : null,
                ProfilePictureKey = key
            });
        }).WithName("CreateProfilePictureUploadUrl");

        group.MapPut("/me/profile-picture-upload", async (
            HttpContext ctx,
            string key,
            IS3StorageService storage) =>
        {
            var userId = ctx.User.GetUserId();
            var expectedPrefix = $"profile-pictures/{userId}/";
            if (!key.StartsWith(expectedPrefix, StringComparison.Ordinal) ||
                key.Contains("..", StringComparison.Ordinal) ||
                key.Contains("://", StringComparison.Ordinal))
            {
                return Results.BadRequest(new
                {
                    error = "Profile picture key must belong to the current user"
                });
            }

            var normalizedContentType = (ctx.Request.ContentType ?? string.Empty)
                .Split(';', 2)[0]
                .Trim()
                .ToLowerInvariant();
            if (!TryGetProfilePictureExtension(normalizedContentType, out _))
            {
                return Results.ValidationProblem(new Dictionary<string, string[]>
                {
                    ["contentType"] =
                    [
                        "Profile picture must be a JPEG, PNG, or WebP image"
                    ]
                });
            }

            await storage.UploadAsync(
                key,
                ctx.Request.Body,
                normalizedContentType,
                ctx.RequestAborted);

            return Results.NoContent();
        }).WithName("UploadProfilePictureThroughApiProxy");

        group.MapPut("/me", async (
            HttpContext ctx,
            UserProfileUpdateDto dto,
            IUserService svc,
            IUserRepository users,
            IValidator<UserProfileUpdateDto> validator,
            IS3StorageService storage) =>
        {
            var validation = await validator.ValidateAsync(dto, ctx.RequestAborted);
            if (!validation.IsValid)
                return Results.ValidationProblem(validation.ToDictionary());

            var userId = ctx.User.GetUserId();
            var user = await svc.UpdateProfileAsync(userId, dto, ctx.RequestAborted);
            return Results.Ok(await ToProfileResponseAsync(user, users, storage, ctx.RequestAborted));
        }).WithName("UpdateCurrentUser");

        group.MapGet("/me/export", async (
            HttpContext ctx,
            IUserService svc,
            ITransactionService txnSvc,
            IBudgetService budgetSvc,
            IRecurringScheduleService recurringScheduleSvc,
            IAlertService alertSvc,
            IWeeklyInsightsRepository weeklyInsightsRepo,
            IPurchasePatternRepository purchasePatternRepo,
            IMonthlyCategorySpendRepository monthlyCategorySpendRepo,
            IAIInteractionRepository aiInteractionRepo,
            IConscienceJourneyRepository conscienceJourneyRepo,
            IPushDeviceTokenRepository pushDeviceTokenRepo) =>
        {
            var userId = ctx.User.GetUserId();
            var ct = ctx.RequestAborted;

            var user = await svc.GetByIdAsync(userId, ct);
            if (user is null) return Results.NotFound();

            var transactions = await txnSvc.ListAsync(userId, 1, 10000, null, ct: ct);
            var budgets = await budgetSvc.ListStatusesByUserAsync(userId, ct: ct);
            var recurringSchedules = await recurringScheduleSvc.ListAsync(userId, ct);
            var alerts = await alertSvc.ListAlertsAsync(userId, ct);
            var weeklyInsights = await weeklyInsightsRepo.GetByUserIdAsync(userId, 1000, ct);
            var purchasePatternSummary = await purchasePatternRepo.GetSummaryAsync(userId, ct);
            var purchasePatternCategories = await purchasePatternRepo.GetCategoriesAsync(userId, ct);
            var purchasePatternMerchants = await purchasePatternRepo.GetMerchantsAsync(userId, ct);
            var monthlyCategorySpends = await monthlyCategorySpendRepo.ListByUserAsync(userId, ct);
            var aiInteractions = await aiInteractionRepo.ListByUserAsync(userId, null, null, 1000, ct);
            var journeyProgress = await conscienceJourneyRepo.GetProgressAsync(userId, ct);
            var journeyBadges = await conscienceJourneyRepo.GetBadgeProgressAsync(userId, ct);
            var journeyQuests = await conscienceJourneyRepo.ListQuestProgressAsync(userId, 1000, ct);
            var journeyEvents = await conscienceJourneyRepo.ListEventsAsync(userId, 1000, ct);
            var journeyMoments = await conscienceJourneyRepo.ListMascotMomentsAsync(userId, 100, ct);
            var pushDevices = await pushDeviceTokenRepo.GetActiveByUserAsync(userId, ct);

            return Results.Ok(new
            {
                ExportedAt = DateTime.UtcNow,
                Profile = new
                {
                    user.Id,
                    user.Email,
                    user.DisplayName,
                    user.ProfilePictureKey,
                    user.PreferredCurrency,
                    user.Locale,
                    user.CreatedAt,
                    user.SpendingPersonality,
                    user.IncomeRange,
                    user.OccupationType,
                    user.HouseholdSize,
                    user.HasCompletedOnboarding,
                    user.AiPersonalityIntensity
                },
                Transactions = transactions.Items,
                Budgets = budgets,
                RecurringSchedules = recurringSchedules,
                Alerts = alerts,
                Insights = new
                {
                    Weekly = weeklyInsights,
                    PurchasePatterns = new
                    {
                        Summary = purchasePatternSummary,
                        Categories = purchasePatternCategories,
                        Merchants = purchasePatternMerchants
                    },
                    MonthlyCategorySpends = monthlyCategorySpends
                },
                AIInteractions = aiInteractions,
                ConscienceJourney = new
                {
                    Progress = journeyProgress,
                    Badges = journeyBadges,
                    Quests = journeyQuests,
                    Events = journeyEvents,
                    MascotMoments = journeyMoments
                },
                PushNotificationDevices = pushDevices.Select(device => new
                {
                    device.Platform,
                    device.CreatedAt,
                    device.UpdatedAt,
                    device.LastSeenAt,
                    device.IsActive
                })
            });
        }).WithName("ExportUserData");

        group.MapDelete("/me", async (
            HttpContext ctx,
            IUserService svc) =>
        {
            var userId = ctx.User.GetUserId();
            await svc.DeleteAccountAsync(userId, ctx.RequestAborted);
            return Results.NoContent();
        }).WithName("DeleteCurrentUser");

        return group;
    }

    private static async Task<object> ToProfileResponseAsync(
        User user,
        IUserRepository users,
        IS3StorageService storage,
        CancellationToken ct)
    {
        var photoUrl = user.ProfilePictureKey is null
            ? null
            : await storage.GeneratePresignedDownloadUrlAsync(
                user.ProfilePictureKey,
                60,
                ct);
        var identities = await users.GetIdentitiesByUserAsync(user.Id, ct);
        var hasPassword = identities.Any(identity =>
            identity.Provider == AuthProvider.Email &&
            identity.HasPassword);

        return new
        {
            user.Id,
            user.Email,
            user.DisplayName,
            user.ProfilePictureKey,
            PhotoUrl = photoUrl,
            user.PreferredCurrency,
            user.Locale,
            user.CreatedAt,
            user.SpendingPersonality,
            user.IncomeRange,
            user.OccupationType,
            user.HouseholdSize,
            user.HasCompletedOnboarding,
            HasPassword = hasPassword,
            user.AiPersonalityIntensity,
        };
    }

    private static bool TryGetProfilePictureExtension(
        string contentType,
        out string extension)
    {
        extension = contentType switch
        {
            "image/jpeg" => ".jpg",
            "image/jpg" => ".jpg",
            "image/png" => ".png",
            "image/webp" => ".webp",
            _ => string.Empty
        };

        return extension.Length > 0;
    }
}
