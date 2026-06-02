namespace Conscia.CognitoCustomEmailSender;

public interface ICognitoCodeDecryptor
{
    string DecryptCode(string encryptedCode);
}
