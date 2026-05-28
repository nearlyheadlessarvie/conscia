using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using Microsoft.Extensions.Configuration;

namespace Conscia.Infrastructure.Configuration;

public static class RuntimeSecretConfigurationLoader
{
    private static readonly (string SecretIdKey, string TargetKey)[] Mappings =
    [
        ("Apple:PrivateKeySecretId", "Apple:PrivateKey"),
        ("GooglePlay:ServiceAccountJsonSecretId", "GooglePlay:ServiceAccountJson"),
        ("Firebase:AdminServiceAccountJsonSecretId", "Firebase:AdminServiceAccountJson")
    ];

    public static async Task<Dictionary<string, string>> LoadAsync(
        IConfiguration configuration,
        bool isProduction,
        IAmazonSecretsManager? secretsManager = null,
        CancellationToken cancellationToken = default)
    {
        if (!isProduction)
        {
            return [];
        }

        var ownsClient = secretsManager is null;
        secretsManager ??= new AmazonSecretsManagerClient();

        try
        {
            var overrides = new Dictionary<string, string>();

            foreach (var (secretIdKey, targetKey) in Mappings)
            {
                var secretId = configuration[secretIdKey];
                if (string.IsNullOrWhiteSpace(secretId))
                {
                    continue;
                }

                var response = await secretsManager.GetSecretValueAsync(new GetSecretValueRequest
                {
                    SecretId = secretId
                }, cancellationToken);

                if (!string.IsNullOrWhiteSpace(response.SecretString))
                {
                    overrides[targetKey] = response.SecretString;
                }
            }

            return overrides;
        }
        finally
        {
            if (ownsClient)
            {
                secretsManager.Dispose();
            }
        }
    }
}
