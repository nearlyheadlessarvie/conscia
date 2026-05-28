using Amazon;
using Amazon.DynamoDBv2;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Conscia.Application.Interfaces;
using Conscia.Application.Lambda;
using Conscia.Application.Services;
using Conscia.Infrastructure.Repositories;
using Conscia.PatternAggregator;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

var services = new ServiceCollection();

services.AddLogging(b => b.AddConsole());

services.AddSingleton<IAmazonDynamoDB>(_ =>
    new AmazonDynamoDBClient(new AmazonDynamoDBConfig
    {
        RegionEndpoint = RegionEndpoint.GetBySystemName(
            Environment.GetEnvironmentVariable("AWS_DEFAULT_REGION") ?? "ap-southeast-1")
    }));

services.AddScoped<IPurchasePatternRepository, PurchasePatternRepository>();
services.AddScoped<IWeeklyInsightsRepository, WeeklyInsightsRepository>();
services.AddScoped<ITransactionRepository, TransactionRepository>();
services.AddScoped<IBehavioralInsightsService, BehavioralInsightsService>();
services.AddScoped<PatternAggregatorService>();

var provider = services.BuildServiceProvider();

Func<ScheduledLambdaEvent?, ILambdaContext, Task> handler = async (_, context) =>
{
    using var scope = provider.CreateScope();
    var aggregator = scope.ServiceProvider.GetRequiredService<PatternAggregatorService>();
    await aggregator.RunAsync();
};

await LambdaBootstrapBuilder.Create(handler, new DefaultLambdaJsonSerializer())
    .Build()
    .RunAsync();
