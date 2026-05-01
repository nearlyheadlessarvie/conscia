using System.Net.Http.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Conscia.AI.Services;

public class OllamaAIService : BaseAIService
{
    private readonly HttpClient _http;
    private readonly string _model;
    private readonly ILogger<OllamaAIService> _logger;

    protected override ILogger Logger => _logger;

    public OllamaAIService(HttpClient http, IConfiguration config, ILogger<OllamaAIService> logger)
    {
        _http = http;
        _model = config["Ollama:Model"] ?? "llama3.2";
        _logger = logger;
    }

    protected override async Task<string> CallLlmAsync(string systemPrompt, string userPrompt, float temperature, CancellationToken ct)
    {
        try
        {
            var request = new OllamaRequest
            {
                Model = _model,
                Messages =
                [
                    new() { Role = "system", Content = systemPrompt },
                    new() { Role = "user", Content = userPrompt }
                ],
                Stream = false,
                Options = new OllamaOptions { Temperature = temperature }
            };

            var response = await _http.PostAsJsonAsync("/api/chat", request, ct);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<OllamaResponse>(ct);
            return result?.Message?.Content?.Trim() ?? "I'm thinking about this...";
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "AI service call failed, returning fallback: {Error}", ex.Message);
            return temperature > 0.5f
                ? "Sometimes a little treat goes a long way!"
                : "Consider sleeping on it before deciding.";
        }
    }
}

internal class OllamaRequest
{
    [JsonPropertyName("model")] public string Model { get; set; } = string.Empty;
    [JsonPropertyName("messages")] public List<OllamaMessage> Messages { get; set; } = [];
    [JsonPropertyName("stream")] public bool Stream { get; set; }
    [JsonPropertyName("options")] public OllamaOptions? Options { get; set; }
}

internal class OllamaMessage
{
    [JsonPropertyName("role")] public string Role { get; set; } = string.Empty;
    [JsonPropertyName("content")] public string Content { get; set; } = string.Empty;
}

internal class OllamaOptions
{
    [JsonPropertyName("temperature")] public float Temperature { get; set; }
}

internal class OllamaResponse
{
    [JsonPropertyName("message")] public OllamaMessage? Message { get; set; }
}
