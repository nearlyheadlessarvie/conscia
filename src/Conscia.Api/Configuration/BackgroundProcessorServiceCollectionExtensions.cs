using Conscia.Infrastructure.Services;

namespace Conscia.Api.Configuration;

public static class BackgroundProcessorServiceCollectionExtensions
{
    public static IServiceCollection AddDevelopmentBackgroundProcessors(this IServiceCollection services)
    {
        services.AddHostedService<RecurringScheduleProcessor>();
        services.AddHostedService<OutboxProcessor>();
        return services;
    }
}
