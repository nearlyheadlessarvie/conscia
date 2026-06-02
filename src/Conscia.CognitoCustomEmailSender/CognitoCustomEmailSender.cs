using System.Net;
using System.Net.Http.Json;
using Conscia.Application.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Conscia.CognitoCustomEmailSender;

public sealed class CognitoCustomEmailSender
{
    private readonly HttpClient _http;
    private readonly BrevoEmailOptions _options;
    private readonly ICognitoCodeDecryptor _decryptor;
    private readonly ILogger<CognitoCustomEmailSender> _logger;

    public CognitoCustomEmailSender(
        HttpClient http,
        IOptions<BrevoEmailOptions> options,
        ICognitoCodeDecryptor decryptor,
        ILogger<CognitoCustomEmailSender> logger)
    {
        _http = http;
        _options = options.Value;
        _decryptor = decryptor;
        _logger = logger;
    }

    public async Task<CognitoCustomEmailSenderEvent> HandleAsync(
        CognitoCustomEmailSenderEvent request,
        CancellationToken ct)
    {
        if (!_options.IsConfigured)
        {
            throw new InvalidOperationException("Cognito email delivery is not configured.");
        }

        var email = GetEmail(request);
        if (string.IsNullOrWhiteSpace(request.Request.Code))
        {
            throw new InvalidOperationException("Cognito custom email sender event did not include an encrypted code.");
        }

        var code = _decryptor.DecryptCode(request.Request.Code);
        var message = BuildMessage(request.TriggerSource, code);

        await SendEmailAsync(email, message, ct);

        _logger.LogInformation(
            "Sent Cognito email for {TriggerSource} to {Email}",
            request.TriggerSource,
            email);

        return request;
    }

    private async Task SendEmailAsync(string email, CognitoEmailMessage message, CancellationToken ct)
    {
        var senderName = string.IsNullOrWhiteSpace(_options.SenderName)
            ? "Conscia"
            : _options.SenderName.Trim();

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
                        email
                    }
                },
                subject = message.Subject,
                htmlContent = message.HtmlContent,
                textContent = message.TextContent
            })
        };
        request.Headers.Add("api-key", _options.ApiKey!.Trim());

        using var response = await _http.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode)
        {
            var responseBody = await response.Content.ReadAsStringAsync(ct);
            _logger.LogWarning(
                "Brevo Cognito email send failed for {Email}. StatusCode: {StatusCode}. Response: {ResponseBody}",
                email,
                (int)response.StatusCode,
                responseBody);
        }

        response.EnsureSuccessStatusCode();
    }

    private static string GetEmail(CognitoCustomEmailSenderEvent request)
    {
        if (request.Request.UserAttributes.TryGetValue("email", out var email) &&
            !string.IsNullOrWhiteSpace(email))
        {
            return email.Trim();
        }

        throw new InvalidOperationException("Cognito custom email sender event did not include an email address.");
    }

    private static CognitoEmailMessage BuildMessage(string? triggerSource, string code)
    {
        return triggerSource switch
        {
            "CustomEmailSender_SignUp" or
            "CustomEmailSender_ResendCode" => CreateCodeMessage(
                "Confirm your Conscia email",
                "Your Conscia confirmation code is:",
                code),

            "CustomEmailSender_ForgotPassword" => CreateCodeMessage(
                "Reset your Conscia password",
                "Use this code to reset your Conscia password:",
                code),

            "CustomEmailSender_UpdateUserAttribute" or
            "CustomEmailSender_VerifyUserAttribute" => CreateCodeMessage(
                "Verify your Conscia email",
                "Use this code to verify your Conscia email:",
                code),

            "CustomEmailSender_Authentication" or
            "CustomEmailSender_EmailMfa" => CreateCodeMessage(
                "Your Conscia sign-in code",
                "Your Conscia sign-in code is:",
                code),

            "CustomEmailSender_AdminCreateUser" => CreateCodeMessage(
                "Your Conscia temporary password",
                "Your temporary Conscia password is:",
                code),

            _ => CreateCodeMessage(
                "Your Conscia verification code",
                "Your Conscia verification code is:",
                code)
        };
    }

    private static CognitoEmailMessage CreateCodeMessage(string subject, string intro, string code)
    {
        var text = $@"{intro}
{code}

If you didn't request this, you can ignore this email.";
        var htmlCode = WebUtility.HtmlEncode(code);
        var html = $@"<html>
  <body style=""font-family: Arial, sans-serif; color: #1f1f1f;"">
    <p>{WebUtility.HtmlEncode(intro)}</p>
    <p style=""font-size:24px;font-weight:700;letter-spacing:4px;"">{htmlCode}</p>
    <p>If you didn't request this, you can ignore this email.</p>
  </body>
</html>";

        return new CognitoEmailMessage(subject, text, html);
    }

    private sealed record CognitoEmailMessage(string Subject, string TextContent, string HtmlContent);
}
