using System.Diagnostics;
using System.Text.Json;
using Conscia.AI.Prompts;
using Conscia.Application.Interfaces;
using Conscia.Application.Models;
using Microsoft.Extensions.Logging;

namespace Conscia.AI.Services;

public abstract class BaseAIService : IAIService
{
    private static readonly ActivitySource AiActivitySource = new("Conscia.AI");

    protected abstract ILogger Logger { get; }

    protected abstract Task<string> CallLlmAsync(string systemPrompt, string userPrompt, float temperature, CancellationToken ct);

    public async Task<AIResponse> GeneratePrePurchaseResponseAsync(AIContext context, CancellationToken ct = default)
    {
        Logger.LogInformation("AI pre-purchase request for user {UserId}: {Amount} {Currency} in {Category}",
            context.UserId, context.Amount, context.CurrencyCode, context.Category);

        var userPrompt = PromptTemplates.BuildPrePurchaseUserPrompt(
            context.Amount, context.CurrencyCode, context.Category,
            context.BudgetPercentUsed, context.RecentRegrets, context.SpendingFrequencyThisWeek);

        return await OrchestrateAsync(userPrompt, context, ct);
    }

    public async Task<AIResponse> GenerateReflectionAsync(AIContext context, CancellationToken ct = default)
    {
        Logger.LogInformation("AI reflection request for user {UserId}: {Amount} {Currency} in {Category}",
            context.UserId, context.Amount, context.CurrencyCode, context.Category);

        var userPrompt = PromptTemplates.BuildReflectionUserPrompt(
            context.Amount, context.CurrencyCode, context.Category,
            context.BudgetPercentUsed, context.RecentRegrets);

        return await OrchestrateAsync(userPrompt, context, ct);
    }

    private async Task<AIResponse> OrchestrateAsync(string userPrompt, AIContext context, CancellationToken ct)
    {
        var sw = Stopwatch.StartNew();

        var impulseTask = TracedLlmCallAsync("impulse", PromptTemplates.ImpulseSystemPrompt, userPrompt, 0.9f, ct);
        var reasonTask = TracedLlmCallAsync("reason", PromptTemplates.ReasonSystemPrompt, userPrompt, 0.3f, ct);

        await Task.WhenAll(impulseTask, reasonTask);

        sw.Stop();
        Logger.LogInformation("AI response generated in {DurationMs}ms", sw.ElapsedMilliseconds);

        return new AIResponse
        {
            DevilMessage = await impulseTask,
            AngelMessage = await reasonTask,
            NeutralMessage = PromptTemplates.BuildNeutralSummary(
                context.Amount, context.CurrencyCode, context.Category, context.BudgetPercentUsed)
        };
    }

    public async Task<UtteranceParseResult> ParseUtteranceAsync(string transcript, CancellationToken ct = default)
    {
        const string systemPrompt = """
            You extract purchase details from spoken utterances.
            Return ONLY valid JSON with exactly these keys:
            { "description": string|null, "amount": number|null, "category": string|null }
            Valid categories: Coffee, Dining, Shopping, Gaming, Travel, Transport, Entertainment, Health, Utilities, Other.
            If a field cannot be determined, use null.
            """;

        var response = await CallLlmAsync(systemPrompt, transcript, 0.1f, ct);

        try
        {
            // Strip markdown code fences if model wraps response
            var json = response.Trim();
            if (json.StartsWith("```"))
            {
                json = string.Join('\n', json.Split('\n').Skip(1));
                json = json[..json.LastIndexOf("```")].Trim();
            }

            var parsed = JsonSerializer.Deserialize<UtteranceParseResult>(
                json,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            return parsed ?? new UtteranceParseResult(transcript, null, null);
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch (Exception ex)
        {
            Logger.LogWarning(ex, "Failed to parse utterance response; returning fallback");
            return new UtteranceParseResult(transcript, null, null);
        }
    }

    private async Task<string> TracedLlmCallAsync(string persona, string systemPrompt, string userPrompt, float temperature, CancellationToken ct)
    {
        using var activity = AiActivitySource.StartActivity("LlmCall");
        activity?.SetTag("llm.persona", persona);
        activity?.SetTag("llm.temperature", temperature);

        var response = await CallLlmAsync(systemPrompt, userPrompt, temperature, ct);
        activity?.SetTag("llm.response_length", response.Length);
        return response;
    }
}
