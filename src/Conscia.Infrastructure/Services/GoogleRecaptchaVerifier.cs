using System.Net.Http.Json;
using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public sealed class GoogleRecaptchaVerifier : ICaptchaVerifier
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    private readonly HttpClient _httpClient;
    private readonly ILogger<GoogleRecaptchaVerifier> _logger;
    private readonly string? _apiKey;
    private readonly string? _projectId;
    private readonly HashSet<string> _allowedSiteKeys;
    private readonly double _minimumScore;

    public GoogleRecaptchaVerifier(
        HttpClient httpClient,
        IConfiguration configuration,
        ILogger<GoogleRecaptchaVerifier> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
        _apiKey = configuration["Recaptcha:ApiKey"];
        _projectId = configuration["Recaptcha:ProjectId"];
        _allowedSiteKeys = ReadAllowedSiteKeys(configuration["Recaptcha:AllowedSiteKeys"]);
        _minimumScore = ReadMinimumScore(configuration["Recaptcha:MinimumScore"]);
    }

    public async Task<bool> VerifyAsync(CaptchaVerificationRequest request, CancellationToken ct = default)
    {
        if (IsDisabled())
        {
            return true;
        }

        if (string.IsNullOrWhiteSpace(request.Token) ||
            string.IsNullOrWhiteSpace(request.SiteKey) ||
            string.IsNullOrWhiteSpace(request.ExpectedAction))
        {
            return false;
        }

        if (!_allowedSiteKeys.Contains(request.SiteKey.Trim()))
        {
            _logger.LogWarning("Rejecting captcha token with an unknown site key.");
            return false;
        }

        try
        {
            var response = await _httpClient.PostAsJsonAsync(
                $"/v1/projects/{Uri.EscapeDataString(_projectId!)}/assessments?key={Uri.EscapeDataString(_apiKey!)}",
                CreateAssessmentRequest(request),
                JsonOptions,
                ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "reCAPTCHA assessment failed with status {StatusCode}.",
                    (int)response.StatusCode);
                return false;
            }

            await using var stream = await response.Content.ReadAsStreamAsync(ct);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: ct);

            return IsAcceptedAssessment(document.RootElement, request.ExpectedAction);
        }
        catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException or JsonException)
        {
            _logger.LogWarning(ex, "reCAPTCHA assessment request failed.");
            return false;
        }
    }

    private bool IsDisabled()
    {
        return string.IsNullOrWhiteSpace(_apiKey) ||
            string.IsNullOrWhiteSpace(_projectId) ||
            _allowedSiteKeys.Count == 0;
    }

    private bool IsAcceptedAssessment(JsonElement root, string expectedAction)
    {
        if (!root.TryGetProperty("tokenProperties", out var tokenProperties) ||
            !tokenProperties.TryGetProperty("valid", out var validElement) ||
            validElement.GetBoolean() != true)
        {
            return false;
        }

        if (!tokenProperties.TryGetProperty("action", out var actionElement) ||
            !string.Equals(actionElement.GetString(), expectedAction, StringComparison.Ordinal))
        {
            return false;
        }

        if (!root.TryGetProperty("riskAnalysis", out var riskAnalysis) ||
            !riskAnalysis.TryGetProperty("score", out var scoreElement))
        {
            return false;
        }

        return scoreElement.GetDouble() >= _minimumScore;
    }

    private static object CreateAssessmentRequest(CaptchaVerificationRequest request)
    {
        return new
        {
            Event = new
            {
                Token = request.Token,
                SiteKey = request.SiteKey,
                ExpectedAction = request.ExpectedAction,
                UserIpAddress = request.UserIpAddress,
                UserAgent = request.UserAgent
            }
        };
    }

    private static HashSet<string> ReadAllowedSiteKeys(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return [];
        }

        return value.Split([',', ';', ' ', '\n', '\r', '\t'], StringSplitOptions.RemoveEmptyEntries)
            .Select(key => key.Trim())
            .Where(key => key.Length > 0)
            .ToHashSet(StringComparer.Ordinal);
    }

    private static double ReadMinimumScore(string? value)
    {
        return double.TryParse(value, NumberStyles.Float, CultureInfo.InvariantCulture, out var minimumScore)
            ? minimumScore
            : 0.5;
    }
}
