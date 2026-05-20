using Amazon;
using Amazon.DynamoDBv2;
using Amazon.SimpleEmailV2;
using Amazon.Lambda.Core;
using Amazon.Lambda.DynamoDBEvents;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Conscia.Application.Configuration;
using Conscia.Application.Interfaces;
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
services.AddSingleton<IAmazonSimpleEmailServiceV2>(_ =>
    new AmazonSimpleEmailServiceV2Client(RegionEndpoint.GetBySystemName(
        Environment.GetEnvironmentVariable("AWS_DEFAULT_REGION") ?? "ap-southeast-1")));

services.AddScoped<ITransactionRepository, TransactionRepository>();
services.AddScoped<IOutboxEventRepository, OutboxEventRepository>();
services.AddScoped<IMonthlyCategorySpendRepository, MonthlyCategorySpendRepository>();
services.AddScoped<IInAppAlertRepository, InAppAlertRepository>();
services.AddScoped<IUserRepository, UserRepository>();
services.AddScoped<IPushDeviceTokenRepository, PushDeviceTokenRepository>();
services.Configure<FirebaseAdminOptions>(options =>
{
    options.AdminServiceAccountJson = Environment.GetEnvironmentVariable("Firebase__AdminServiceAccountJson");
    options.ProjectId = Environment.GetEnvironmentVariable("Firebase__ProjectId");
});
services.Configure<InviteEmailOptions>(options =>
{
    options.FromEmail = Environment.GetEnvironmentVariable("InviteEmail__FromEmail")
        ?? Environment.GetEnvironmentVariable("SES_FROM_EMAIL");
    options.ConfigurationSetName = Environment.GetEnvironmentVariable("InviteEmail__ConfigurationSetName")
        ?? Environment.GetEnvironmentVariable("SES_CONFIGURATION_SET");
    options.DeepLinkBaseUri = Environment.GetEnvironmentVariable("InviteEmail__DeepLinkBaseUri")
        ?? "https://getconscia.com/open/family-invite";
});
services.AddHttpClient<IPushNotificationSender, FirebasePushNotificationSender>();
services.AddScoped<IInviteEmailSender, SesInviteEmailSender>();

services.AddScoped<OutboxProcessor>();

var provider = services.BuildServiceProvider();

Func<DynamoDBEvent, ILambdaContext, Task> handler = async (_, context) =>
{
    using var scope = provider.CreateScope();
    var processor = scope.ServiceProvider.GetRequiredService<OutboxProcessor>();
    await processor.ProcessBatchAsync(CancellationToken.None);
};

await LambdaBootstrapBuilder.Create(handler, new DefaultLambdaJsonSerializer())
    .Build()
    .RunAsync();
