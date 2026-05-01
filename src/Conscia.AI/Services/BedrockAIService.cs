using System.Text;
using System.Text.Json;
using Amazon.BedrockRuntime;
using Amazon.BedrockRuntime.Model;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Conscia.AI.Services;

public class BedrockAIService : BaseAIService
{
    private readonly IAmazonBedrockRuntime _bedrock;
    private readonly BedrockOptions _options;
    private readonly ILogger<BedrockAIService> _logger;

    protected override ILogger Logger => _logger;

    public BedrockAIService(IAmazonBedrockRuntime bedrock, IOptions<BedrockOptions> options, ILogger<BedrockAIService> logger)
    {
        _bedrock = bedrock;
        _options = options.Value;
        _logger = logger;
    }

    protected override async Task<string> CallLlmAsync(string systemPrompt, string userPrompt, float temperature, CancellationToken ct)
    {
        try
        {
            var payload = JsonSerializer.Serialize(new
            {
                anthropic_version = "bedrock-2023-05-31",
                max_tokens = _options.MaxTokens,
                temperature,
                system = systemPrompt,
                messages = new[]
                {
                    new { role = "user", content = userPrompt }
                }
            });

            using var bodyStream = new MemoryStream(Encoding.UTF8.GetBytes(payload));
            var request = new InvokeModelRequest
            {
                ModelId = _options.ModelId,
                ContentType = "application/json",
                Accept = "application/json",
                Body = bodyStream
            };

            var response = await _bedrock.InvokeModelAsync(request, ct);

            using var reader = new StreamReader(response.Body);
            var responseJson = await reader.ReadToEndAsync(ct);
            using var doc = JsonDocument.Parse(responseJson);

            var content = doc.RootElement
                .GetProperty("content")[0]
                .GetProperty("text")
                .GetString();

            return content?.Trim() ?? "I'm thinking about this...";
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
