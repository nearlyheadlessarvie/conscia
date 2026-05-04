using Conscia.Application.Interfaces;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public class InsightsProcessor
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<InsightsProcessor> _logger;

    public InsightsProcessor(IServiceScopeFactory scopeFactory, ILogger<InsightsProcessor> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    public async Task ProcessInsightsForUserAsync(Guid userId, CancellationToken ct = default)
    {
        using var scope = _scopeFactory.CreateScope();
        var insightsService = scope.ServiceProvider.GetRequiredService<IBehavioralInsightsService>();

        try
        {
            // Calculate insights for the current week
            var weekStart = GetStartOfWeek(DateTime.UtcNow);
            await insightsService.CalculateAndStoreWeeklyInsightsAsync(userId, weekStart, ct);

            _logger.LogInformation("Calculated insights for user {UserId}", userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calculating insights for user {UserId}", userId);
            throw;
        }
    }

    private static DateTime GetStartOfWeek(DateTime date)
    {
        // Get the start of the week (Monday)
        var diff = (7 + (date.DayOfWeek - DayOfWeek.Monday)) % 7;
        return date.AddDays(-1 * diff).Date;
    }
}