using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Conscia.Application.Configuration;
using Conscia.Application.Interfaces;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Conscia.Infrastructure.Services;

public sealed class FirebasePushNotificationSender : IPushNotificationSender
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private const string Scope = "https://www.googleapis.com/auth/firebase.messaging";

    private readonly HttpClient _http;
    private readonly IPushDeviceTokenRepository _tokens;
    private readonly FirebaseAdminOptions _options;
    private readonly ILogger<FirebasePushNotificationSender> _logger;

    public FirebasePushNotificationSender(
        HttpClient http,
        IPushDeviceTokenRepository tokens,
        IOptions<FirebaseAdminOptions> options,
        ILogger<FirebasePushNotificationSender> logger)
    {
        _http = http;
        _tokens = tokens;
        _options = options.Value;
        _logger = logger;
    }

    public async Task SendToUserAsync(
        Guid userId,
        string title,
        string body,
        string? route,
        CancellationToken ct = default)
    {
        if (!_options.IsConfigured)
        {
            throw new InvalidOperationException("Firebase push notifications are not configured.");
        }

        var deviceTokens = await _tokens.GetActiveByUserAsync(userId, ct);
        if (deviceTokens.Count == 0)
        {
            _logger.LogDebug("No active push tokens found for user {UserId}", userId);
            return;
        }

        var accessToken = await GetAccessTokenAsync(ct);
        var endpoint = $"https://fcm.googleapis.com/v1/projects/{_options.ResolvedProjectId}/messages:send";

        foreach (var deviceToken in deviceTokens)
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, endpoint);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            request.Content = new StringContent(
                JsonSerializer.Serialize(new
                {
                    message = new
                    {
                        token = deviceToken.Token,
                        notification = new
                        {
                            title,
                            body
                        },
                        data = route is null
                            ? null
                            : new Dictionary<string, string>
                            {
                                ["route"] = route
                            }
                    }
                }, JsonOptions),
                Encoding.UTF8,
                "application/json");

            using var response = await _http.SendAsync(request, ct);
            if (!response.IsSuccessStatusCode)
            {
                var payload = await response.Content.ReadAsStringAsync(ct);
                throw new InvalidOperationException(
                    $"Firebase push delivery failed with {(int)response.StatusCode}: {payload}");
            }
        }
    }

    private async Task<string> GetAccessTokenAsync(CancellationToken ct)
    {
        var credential = GoogleCredential
            .FromJson(_options.ResolvedServiceAccountJson!)
            .CreateScoped(Scope);

        return await credential.UnderlyingCredential.GetAccessTokenForRequestAsync(
            cancellationToken: ct);
    }
}
