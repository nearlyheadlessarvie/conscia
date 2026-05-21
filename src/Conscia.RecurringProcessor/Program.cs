using Amazon;
using Amazon.DynamoDBv2;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Conscia.Application.Interfaces;
using Conscia.Application.Services;
using Conscia.Infrastructure.Repositories;
using Conscia.Infrastructure.Services;
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

services.AddScoped<ITransactionRepository, TransactionRepository>();
services.AddScoped<IRecurringScheduleRepository, RecurringScheduleRepository>();
services.AddScoped<IInAppAlertRepository, InAppAlertRepository>();
services.AddSingleton<IRecurringScheduleGenerator, RecurringScheduleGenerator>();
services.AddScoped<RecurringScheduleProcessor>();

var provider = services.BuildServiceProvider();

Func<string?, ILambdaContext, Task> handler = async (_, context) =>
{
    using var scope = provider.CreateScope();
    var processor = scope.ServiceProvider.GetRequiredService<RecurringScheduleProcessor>();
    await processor.ProcessOnceAsync(CancellationToken.None);
};

await LambdaBootstrapBuilder.Create(handler, new DefaultLambdaJsonSerializer())
    .Build()
    .RunAsync();
