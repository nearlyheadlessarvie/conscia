using System.Globalization;
using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Logging;

namespace Conscia.Infrastructure.Services;

public sealed class SesEmailEventProcessor
{
    private readonly IEmailSuppressionRepository _suppressions;
    private readonly ILogger<SesEmailEventProcessor> _logger;

    public SesEmailEventProcessor(
        IEmailSuppressionRepository suppressions,
        ILogger<SesEmailEventProcessor> logger)
    {
        _suppressions = suppressions;
        _logger = logger;
    }

    public async Task<bool> TryProcessAsync(JsonElement evt, CancellationToken ct = default)
    {
        if (!TryGetString(evt, "source", out var source)
            || !string.Equals(source, "aws.ses", StringComparison.Ordinal)
            || !TryGetString(evt, "detail-type", out var detailType)
            || !evt.TryGetProperty("detail", out var detail))
        {
            return false;
        }

        var eventId = TryGetString(evt, "id", out var id) ? id : null;
        var occurredAt = TryGetDateTime(evt, "time") ?? DateTime.UtcNow;
        var providerMessageId = TryGetMailMessageId(detail);

        switch (detailType)
        {
            case "Email Bounced":
                await ProcessBounceAsync(detail, eventId, providerMessageId, occurredAt, ct);
                return true;
            case "Email Complaint Received":
                await SuppressRecipientsAsync(
                    ReadRecipientEmails(detail, "complaint", "complainedRecipients"),
                    EmailSuppressionReason.Complaint,
                    eventId,
                    providerMessageId,
                    occurredAt,
                    ct);
                return true;
            default:
                return false;
        }
    }

    private async Task ProcessBounceAsync(
        JsonElement detail,
        string? eventId,
        string? providerMessageId,
        DateTime occurredAt,
        CancellationToken ct)
    {
        if (!detail.TryGetProperty("bounce", out var bounce)
            || !TryGetString(bounce, "bounceType", out var bounceType)
            || !string.Equals(bounceType, "Permanent", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation("Ignoring non-permanent SES bounce event {EventId}", eventId);
            return;
        }

        await SuppressRecipientsAsync(
            ReadRecipientEmails(detail, "bounce", "bouncedRecipients"),
            EmailSuppressionReason.HardBounce,
            eventId,
            providerMessageId,
            occurredAt,
            ct);
    }

    private async Task SuppressRecipientsAsync(
        IReadOnlyList<string> emails,
        EmailSuppressionReason reason,
        string? eventId,
        string? providerMessageId,
        DateTime occurredAt,
        CancellationToken ct)
    {
        foreach (var email in emails)
        {
            await _suppressions.UpsertAsync(new EmailSuppression
            {
                Email = email,
                Reason = reason,
                Source = "SES",
                SuppressedAt = occurredAt,
                SourceEventId = eventId,
                ProviderMessageId = providerMessageId
            }, ct);

            _logger.LogInformation(
                "Suppressed email {Email} after SES {Reason} event {EventId}",
                email,
                reason,
                eventId);
        }
    }

    private static IReadOnlyList<string> ReadRecipientEmails(
        JsonElement detail,
        string containerName,
        string recipientsName)
    {
        if (!detail.TryGetProperty(containerName, out var container)
            || !container.TryGetProperty(recipientsName, out var recipients)
            || recipients.ValueKind != JsonValueKind.Array)
        {
            return [];
        }

        return recipients
            .EnumerateArray()
            .Select(recipient => TryGetString(recipient, "emailAddress", out var email)
                ? email.Trim().ToLowerInvariant()
                : string.Empty)
            .Where(email => !string.IsNullOrWhiteSpace(email))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
    }

    private static string? TryGetMailMessageId(JsonElement detail)
    {
        return detail.TryGetProperty("mail", out var mail)
            && TryGetString(mail, "messageId", out var messageId)
                ? messageId
                : null;
    }

    private static bool TryGetString(JsonElement element, string propertyName, out string value)
    {
        value = string.Empty;
        if (!element.TryGetProperty(propertyName, out var property)
            || property.ValueKind != JsonValueKind.String)
        {
            return false;
        }

        value = property.GetString() ?? string.Empty;
        return !string.IsNullOrWhiteSpace(value);
    }

    private static DateTime? TryGetDateTime(JsonElement element, string propertyName)
    {
        return TryGetString(element, propertyName, out var value)
            && DateTime.TryParse(value, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind, out var parsed)
                ? parsed
                : null;
    }
}
