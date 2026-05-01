using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace Conscia.Api.Health;

public class AIServiceHealthCheck(
    IHttpClientFactory httpClientFactory,
    IConfiguration configuration,
    IWebHostEnvironment environment) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        if (!environment.IsDevelopment())
        {
            // Bedrock has no cheap health-ping endpoint; trust the SDK
            return HealthCheckResult.Healthy("Bedrock SDK assumed available.");
        }

        try
        {
            var baseUrl = configuration["Ollama:BaseUrl"] ?? "http://localhost:11434";
            using var client = httpClientFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(5);

            var response = await client.GetAsync($"{baseUrl}/api/tags", cancellationToken);
            return response.IsSuccessStatusCode
                ? HealthCheckResult.Healthy()
                : HealthCheckResult.Unhealthy($"Ollama returned {response.StatusCode}.");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("Ollama is unreachable.", ex);
        }
    }
}
