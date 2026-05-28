using System.Text.Json.Serialization;

namespace Conscia.CognitoPreSignupLinker;

public sealed class CognitoPreSignupEvent
{
    [JsonPropertyName("triggerSource")]
    public string? TriggerSource { get; set; }

    [JsonPropertyName("userPoolId")]
    public string? UserPoolId { get; set; }

    [JsonPropertyName("userName")]
    public string? UserName { get; set; }

    [JsonPropertyName("request")]
    public CognitoPreSignupRequest Request { get; set; } = new();

    [JsonPropertyName("response")]
    public CognitoPreSignupResponse Response { get; set; } = new();
}

public sealed class CognitoPreSignupRequest
{
    [JsonPropertyName("userAttributes")]
    public Dictionary<string, string> UserAttributes { get; set; } = new(StringComparer.OrdinalIgnoreCase);
}

public sealed class CognitoPreSignupResponse
{
    [JsonPropertyName("autoConfirmUser")]
    public bool AutoConfirmUser { get; set; }

    [JsonPropertyName("autoVerifyEmail")]
    public bool AutoVerifyEmail { get; set; }

    [JsonPropertyName("autoVerifyPhone")]
    public bool AutoVerifyPhone { get; set; }
}
