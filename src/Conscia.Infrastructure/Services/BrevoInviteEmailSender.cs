using System.Net.Http.Json;
using Conscia.Application.Configuration;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Conscia.Infrastructure.Services;

public sealed class BrevoInviteEmailSender : IInviteEmailSender
{
    private readonly HttpClient _http;
    private readonly BrevoEmailOptions _options;
    private readonly ILogger<BrevoInviteEmailSender> _logger;

    public BrevoInviteEmailSender(
        HttpClient http,
        IOptions<BrevoEmailOptions> options,
        ILogger<BrevoInviteEmailSender> logger)
    {
        _http = http;
        _options = options.Value;
        _logger = logger;
    }

    public async Task SendFamilyInviteAsync(FamilyInviteEmailMessage message, CancellationToken ct = default)
    {
        if (!_options.IsConfigured)
        {
            throw new InvalidOperationException("Invite email delivery is not configured.");
        }

        var senderName = string.IsNullOrWhiteSpace(_options.SenderName)
            ? "Conscia"
            : _options.SenderName.Trim();
        var familySpaceName = string.IsNullOrWhiteSpace(message.FamilySpaceName)
            ? "your Family Space"
            : message.FamilySpaceName;

        var subject = $"Family invite to {familySpaceName}";
        var plainTextBody = $@"You were invited to join {familySpaceName} in Conscia.

Open the invite in the app:
{message.InviteLink}

This invite expires on {message.ExpiresAt:MMMM d, yyyy}.";

        var htmlBody = $@"<html>
  <body style=""font-family: Arial, sans-serif; color: #1f1f1f;"">
    <h2>Family invite</h2>
    <p>You were invited to join <strong>{System.Net.WebUtility.HtmlEncode(familySpaceName)}</strong> in Conscia.</p>
    <p>
      <a href=""{System.Net.WebUtility.HtmlEncode(message.InviteLink)}""
         style=""display:inline-block;padding:12px 20px;background:#1f2d70;color:#ffffff;text-decoration:none;border-radius:999px;"">
         Open invite in Conscia
      </a>
    </p>
    <p>This invite expires on {message.ExpiresAt:MMMM d, yyyy}.</p>
  </body>
</html>";

        using var request = new HttpRequestMessage(HttpMethod.Post, "/v3/smtp/email")
        {
            Content = JsonContent.Create(new
            {
                sender = new
                {
                    email = _options.SenderEmail!.Trim(),
                    name = senderName
                },
                to = new[]
                {
                    new
                    {
                        email = message.RecipientEmail
                    }
                },
                subject,
                htmlContent = htmlBody,
                textContent = plainTextBody
            })
        };
        request.Headers.Add("api-key", _options.ApiKey!.Trim());

        using var response = await _http.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode)
        {
            var responseBody = await response.Content.ReadAsStringAsync(ct);
            _logger.LogWarning(
                "Brevo invite email send failed for {InviteId} to {Email}. StatusCode: {StatusCode}. Response: {ResponseBody}",
                message.InviteId,
                message.RecipientEmail,
                (int)response.StatusCode,
                responseBody);
        }

        response.EnsureSuccessStatusCode();

        _logger.LogInformation(
            "Sent family invite email {InviteId} to {Email}",
            message.InviteId,
            message.RecipientEmail);
    }
}
