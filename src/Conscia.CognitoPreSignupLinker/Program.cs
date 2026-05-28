using Amazon.CognitoIdentityProvider;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Conscia.CognitoPreSignupLinker;
using Microsoft.Extensions.Logging;

var loggerFactory = LoggerFactory.Create(builder => builder.AddConsole());
var logger = loggerFactory.CreateLogger<CognitoPreSignupLinker>();
var cognito = new AmazonCognitoIdentityProviderClient();
var linker = new CognitoPreSignupLinker(cognito, logger);

Func<CognitoPreSignupEvent, ILambdaContext, Task<CognitoPreSignupEvent>> handler = async (request, _) =>
    await linker.HandleAsync(request, CancellationToken.None);

await LambdaBootstrapBuilder.Create(handler, new DefaultLambdaJsonSerializer())
    .Build()
    .RunAsync();
