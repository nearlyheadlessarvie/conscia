using Conscia.Api.Configuration;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace Conscia.Tests.Unit.Api;

public class BackgroundServiceRegistrationTests
{
    [Fact]
    public void AddDevelopmentBackgroundProcessors_RegistersRecurringAndOutboxWorkers()
    {
        var services = new ServiceCollection();

        services.AddDevelopmentBackgroundProcessors();

        Assert.Contains(services, IsHostedService<RecurringScheduleProcessor>());
        Assert.Contains(services, IsHostedService<OutboxProcessor>());
    }

    private static Predicate<ServiceDescriptor> IsHostedService<TImplementation>()
        where TImplementation : IHostedService =>
        descriptor => descriptor.ServiceType == typeof(IHostedService)
            && descriptor.ImplementationType == typeof(TImplementation);
}
