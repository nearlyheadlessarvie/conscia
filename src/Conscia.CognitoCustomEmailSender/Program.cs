using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Conscia.Application.Configuration;
using Conscia.CognitoCustomEmailSender;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

var loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
var logger = loggerFactory.CreateLogger<CognitoCustomEmailSender>();
var http = new HttpClient
{
    BaseAddress = new Uri("https://api.brevo.com")
};
using var decryptor = new AwsEncryptionSdkCognitoCodeDecryptor(
    GetRequired("COGNITO_CUSTOM_SENDER_KMS_KEY_ARN"));
var sender = new CognitoCustomEmailSender(
    http,
    Options.Create(new BrevoEmailOptions
    {
        ApiKey = GetOptional("Brevo__ApiKey") ?? GetRequired("BREVO_API_KEY"),
        SenderEmail = GetOptional("Brevo__SenderEmail") ?? GetRequired("BREVO_SENDER_EMAIL"),
        SenderName = GetOptional("Brevo__SenderName") ?? GetOptional("BREVO_SENDER_NAME") ?? "Conscia"
    }),
    decryptor,
    logger);

Func<CognitoCustomEmailSenderEvent, ILambdaContext, Task<CognitoCustomEmailSenderEvent>> handler = async (request, _) =>
    await sender.HandleAsync(request, CancellationToken.None);

await LambdaBootstrapBuilder.Create(handler, new DefaultLambdaJsonSerializer())
    .Build()
    .RunAsync();

static string? GetOptional(string name)
{
    var value = Environment.GetEnvironmentVariable(name);
    return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}

static string GetRequired(string name) =>
    GetOptional(name) ?? throw new InvalidOperationException($"{name} must be configured.");
