using System.Text.Json;
using System.Text.Json.Serialization;

namespace Conscia.CognitoCustomEmailSender;

public sealed class CognitoCustomEmailSenderEvent
{
    [JsonPropertyName("version")]
    public string Version { get; set; } = "1";

    [JsonPropertyName("triggerSource")]
    public string? TriggerSource { get; set; }

    [JsonPropertyName("userPoolId")]
    public string? UserPoolId { get; set; }

    [JsonPropertyName("userName")]
    public string? UserName { get; set; }

    [JsonPropertyName("request")]
    public CognitoCustomEmailSenderRequest Request { get; set; } = new();

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtensionData { get; set; }
}

public sealed class CognitoCustomEmailSenderRequest
{
    [JsonPropertyName("type")]
    public string? Type { get; set; }

    [JsonPropertyName("code")]
    public string? Code { get; set; }

    [JsonPropertyName("userAttributes")]
    public Dictionary<string, string> UserAttributes { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    [JsonPropertyName("clientMetadata")]
    public Dictionary<string, string> ClientMetadata { get; set; } = new(StringComparer.OrdinalIgnoreCase);

    [JsonExtensionData]
    public Dictionary<string, JsonElement>? ExtensionData { get; set; }
}
