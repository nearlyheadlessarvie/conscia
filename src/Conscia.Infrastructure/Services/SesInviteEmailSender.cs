using Amazon.SimpleEmailV2;
using Amazon.SimpleEmailV2.Model;
using Conscia.Application.Configuration;
using Conscia.Application.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Conscia.Infrastructure.Services;

public sealed class SesInviteEmailSender : IInviteEmailSender
{
    private readonly IAmazonSimpleEmailServiceV2 _ses;
    private readonly InviteEmailOptions _options;
    private readonly ILogger<SesInviteEmailSender> _logger;

    public SesInviteEmailSender(
        IAmazonSimpleEmailServiceV2 ses,
        IOptions<InviteEmailOptions> options,
        ILogger<SesInviteEmailSender> logger)
    {
        _ses = ses;
        _options = options.Value;
        _logger = logger;
    }

    public async Task SendFamilyInviteAsync(FamilyInviteEmailMessage message, CancellationToken ct = default)
    {
        if (!_options.IsConfigured)
        {
            throw new InvalidOperationException("Invite email delivery is not configured.");
        }

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

        var request = new SendEmailRequest
        {
            FromEmailAddress = _options.FromEmail,
            ConfigurationSetName = string.IsNullOrWhiteSpace(_options.ConfigurationSetName)
                ? null
                : _options.ConfigurationSetName,
            Destination = new Destination
            {
                ToAddresses = [message.RecipientEmail]
            },
            Content = new EmailContent
            {
                Simple = new Message
                {
                    Subject = new Content { Data = subject },
                    Body = new Body
                    {
                        Text = new Content { Data = plainTextBody },
                        Html = new Content { Data = htmlBody }
                    }
                }
            }
        };

        await _ses.SendEmailAsync(request, ct);

        _logger.LogInformation(
            "Sent family invite email {InviteId} to {Email}",
            message.InviteId,
            message.RecipientEmail);
    }
}
