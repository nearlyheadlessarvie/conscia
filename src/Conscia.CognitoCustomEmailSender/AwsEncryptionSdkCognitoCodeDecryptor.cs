using System.Net;
using System.Text;
using Amazon.KeyManagementService;
using AWS.Cryptography.EncryptionSDK;
using AWS.Cryptography.MaterialProviders;

namespace Conscia.CognitoCustomEmailSender;

public sealed class AwsEncryptionSdkCognitoCodeDecryptor : ICognitoCodeDecryptor, IDisposable
{
    private readonly string _kmsKeyArn;
    private readonly AmazonKeyManagementServiceClient _kms;

    public AwsEncryptionSdkCognitoCodeDecryptor(string kmsKeyArn)
    {
        if (string.IsNullOrWhiteSpace(kmsKeyArn))
        {
            throw new ArgumentException("Cognito custom sender KMS key ARN is required.", nameof(kmsKeyArn));
        }

        _kmsKeyArn = kmsKeyArn;
        _kms = new AmazonKeyManagementServiceClient();
    }

    public string DecryptCode(string encryptedCode)
    {
        var encryptedBytes = Convert.FromBase64String(encryptedCode);
        var encryptionSdk = new ESDK(new AwsEncryptionSdkConfig());
        var materialProviders = new MaterialProviders(new MaterialProvidersConfig());
        var keyring = materialProviders.CreateAwsKmsKeyring(new CreateAwsKmsKeyringInput
        {
            KmsClient = _kms,
            KmsKeyId = _kmsKeyArn
        });

        var output = encryptionSdk.Decrypt(new DecryptInput
        {
            Ciphertext = new MemoryStream(encryptedBytes),
            Keyring = keyring
        });

        return WebUtility.HtmlDecode(Encoding.UTF8.GetString(output.Plaintext.ToArray()));
    }

    public void Dispose()
    {
        _kms.Dispose();
    }
}
