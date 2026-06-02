using Amazon;
using Amazon.DynamoDBv2;
using Amazon.Lambda.Core;
using Amazon.Lambda.DynamoDBEvents;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Conscia.Application.Configuration;
using Conscia.Application.Interfaces;
using Conscia.Infrastructure.Repositories;
using Conscia.Infrastructure.Configuration;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

var configuration = new ConfigurationManager();
configuration.AddInMemoryCollection(new Dictionary<string, string?>
{
    ["Firebase:AdminServiceAccountJson"] = Environment.GetEnvironmentVariable("Firebase__AdminServiceAccountJson"),
    ["Firebase:AdminServiceAccountJsonSecretId"] = Environment.GetEnvironmentVariable("Firebase__AdminServiceAccountJsonSecretId"),
    ["Firebase:ProjectId"] = Environment.GetEnvironmentVariable("Firebase__ProjectId")
});
var runtimeSecretOverrides = await RuntimeSecretConfigurationLoader.LoadAsync(
    configuration,
    isProduction: !string.Equals(
        Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT"),
        "Development",
        StringComparison.OrdinalIgnoreCase));
if (runtimeSecretOverrides.Count > 0)
{
    configuration.AddInMemoryCollection(runtimeSecretOverrides.ToDictionary(
        pair => pair.Key,
        pair => (string?)pair.Value));
}

var services = new ServiceCollection();
services.AddLogging(b => b.AddConsole());

services.AddSingleton<IAmazonDynamoDB>(_ =>
    new AmazonDynamoDBClient(new AmazonDynamoDBConfig
    {
        RegionEndpoint = RegionEndpoint.GetBySystemName(
            Environment.GetEnvironmentVariable("AWS_DEFAULT_REGION") ?? "ap-southeast-1")
    }));

services.AddScoped<ITransactionRepository, TransactionRepository>();
services.AddScoped<IOutboxEventRepository, OutboxEventRepository>();
services.AddScoped<IMonthlyCategorySpendRepository, MonthlyCategorySpendRepository>();
services.AddScoped<IInAppAlertRepository, InAppAlertRepository>();
services.AddScoped<IUserRepository, UserRepository>();
services.AddScoped<IPushDeviceTokenRepository, PushDeviceTokenRepository>();
services.Configure<FirebaseAdminOptions>(configuration.GetSection(FirebaseAdminOptions.SectionName));
services.Configure<InviteEmailOptions>(options =>
{
    options.FromEmail = Environment.GetEnvironmentVariable("InviteEmail__FromEmail")
        ?? Environment.GetEnvironmentVariable("SES_FROM_EMAIL");
    options.ConfigurationSetName = Environment.GetEnvironmentVariable("InviteEmail__ConfigurationSetName")
        ?? Environment.GetEnvironmentVariable("SES_CONFIGURATION_SET");
    options.DeepLinkBaseUri = Environment.GetEnvironmentVariable("InviteEmail__DeepLinkBaseUri")
        ?? "https://getconscia.com/open/family-invite";
});
services.Configure<BrevoEmailOptions>(options =>
{
    options.ApiKey = Environment.GetEnvironmentVariable("Brevo__ApiKey")
        ?? Environment.GetEnvironmentVariable("BREVO_API_KEY");
    options.SenderEmail = Environment.GetEnvironmentVariable("Brevo__SenderEmail")
        ?? Environment.GetEnvironmentVariable("BREVO_SENDER_EMAIL")
        ?? Environment.GetEnvironmentVariable("InviteEmail__FromEmail")
        ?? Environment.GetEnvironmentVariable("SES_FROM_EMAIL");
    options.SenderName = Environment.GetEnvironmentVariable("Brevo__SenderName")
        ?? Environment.GetEnvironmentVariable("BREVO_SENDER_NAME")
        ?? "Conscia";
});
services.AddHttpClient<IPushNotificationSender, FirebasePushNotificationSender>();
services.AddHttpClient<IInviteEmailSender, BrevoInviteEmailSender>(client =>
{
    client.BaseAddress = new Uri("https://api.brevo.com");
});

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
