using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using Conscia.Infrastructure.Configuration;
using Microsoft.Extensions.Configuration;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class RuntimeSecretConfigurationLoaderTests
{
    [Fact]
    public async Task LoadAsync_SkipsSecretFetchOutsideProduction()
    {
        var configuration = new ConfigurationManager();
        configuration.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Auth:AppJwtSigningKeySecretId"] = "conscia/dev/auth"
        });

        var secretsManager = new Mock<IAmazonSecretsManager>(MockBehavior.Strict);

        await RuntimeSecretConfigurationLoader.LoadAsync(
            configuration,
            isProduction: false,
            secretsManager: secretsManager.Object);

        Assert.Null(configuration["Auth:AppJwtSigningKey"]);
    }

    [Fact]
    public async Task LoadAsync_HydratesMappedConfigurationKeysFromSecretsManager()
    {
        var configuration = new ConfigurationManager();
        configuration.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["Auth:AppJwtSigningKeySecretId"] = "conscia/prod/auth-app-jwt-signing-key",
            ["Firebase:AdminServiceAccountJsonSecretId"] = "conscia/prod/firebase-admin-service-account-json"
        });

        var secretsManager = new Mock<IAmazonSecretsManager>();
        secretsManager
            .Setup(client => client.GetSecretValueAsync(
                It.Is<GetSecretValueRequest>(request => request.SecretId == "conscia/prod/auth-app-jwt-signing-key"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new GetSecretValueResponse
            {
                SecretString = "jwt-signing-key"
            });
        secretsManager
            .Setup(client => client.GetSecretValueAsync(
                It.Is<GetSecretValueRequest>(request => request.SecretId == "conscia/prod/firebase-admin-service-account-json"),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new GetSecretValueResponse
            {
                SecretString = "{\"project_id\":\"conscia-prod\"}"
            });

        var overrides = await RuntimeSecretConfigurationLoader.LoadAsync(
            configuration,
            isProduction: true,
            secretsManager: secretsManager.Object);

        configuration.AddInMemoryCollection(overrides.ToDictionary(
            pair => pair.Key,
            pair => (string?)pair.Value));
        Assert.Equal("jwt-signing-key", configuration["Auth:AppJwtSigningKey"]);
        Assert.Equal("{\"project_id\":\"conscia-prod\"}", configuration["Firebase:AdminServiceAccountJson"]);
    }
}
