using Conscia.Application.Interfaces;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public sealed class NoopInviteEmailSender : IInviteEmailSender
{
    private readonly ILogger<NoopInviteEmailSender> _logger;

    public NoopInviteEmailSender(ILogger<NoopInviteEmailSender> logger)
    {
        _logger = logger;
    }

    public Task SendFamilyInviteAsync(FamilyInviteEmailMessage message, CancellationToken ct = default)
    {
        _logger.LogInformation(
            "Invite email sender is not configured. Skipping family invite email for {Email} ({InviteId})",
            message.RecipientEmail,
            message.InviteId);
        return Task.CompletedTask;
    }
}
