using System.Text.Json;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;

namespace Conscia.Tests.Unit.Infrastructure;

public class SesEmailEventProcessorTests
{
    private readonly Mock<IEmailSuppressionRepository> _suppressions = new();

    [Fact]
    public async Task TryProcessAsync_SuppressesPermanentBounceRecipients()
    {
        var processor = CreateProcessor();
        using var document = JsonDocument.Parse(SesEvent("Email Bounced", """
            {
              "eventType": "Bounce",
              "mail": { "messageId": "ses-message-1" },
              "bounce": {
                "bounceType": "Permanent",
                "bouncedRecipients": [
                  { "emailAddress": " Bounced@Example.COM " }
                ]
              }
            }
            """));

        var processed = await processor.TryProcessAsync(document.RootElement, CancellationToken.None);

        Assert.True(processed);
        _suppressions.Verify(r => r.UpsertAsync(
            It.Is<EmailSuppression>(suppression =>
                suppression.Email == "bounced@example.com" &&
                suppression.Reason == EmailSuppressionReason.HardBounce &&
                suppression.Source == "SES" &&
                suppression.SourceEventId == "event-1" &&
                suppression.ProviderMessageId == "ses-message-1"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task TryProcessAsync_DoesNotSuppressTransientBounceRecipients()
    {
        var processor = CreateProcessor();
        using var document = JsonDocument.Parse(SesEvent("Email Bounced", """
            {
              "eventType": "Bounce",
              "mail": { "messageId": "ses-message-1" },
              "bounce": {
                "bounceType": "Transient",
                "bouncedRecipients": [
                  { "emailAddress": "delayed@example.com" }
                ]
              }
            }
            """));

        var processed = await processor.TryProcessAsync(document.RootElement, CancellationToken.None);

        Assert.True(processed);
        _suppressions.Verify(r => r.UpsertAsync(
            It.IsAny<EmailSuppression>(),
            It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task TryProcessAsync_SuppressesComplaintRecipients()
    {
        var processor = CreateProcessor();
        using var document = JsonDocument.Parse(SesEvent("Email Complaint Received", """
            {
              "eventType": "Complaint",
              "mail": { "messageId": "ses-message-2" },
              "complaint": {
                "complainedRecipients": [
                  { "emailAddress": "complained@example.com" }
                ]
              }
            }
            """));

        var processed = await processor.TryProcessAsync(document.RootElement, CancellationToken.None);

        Assert.True(processed);
        _suppressions.Verify(r => r.UpsertAsync(
            It.Is<EmailSuppression>(suppression =>
                suppression.Email == "complained@example.com" &&
                suppression.Reason == EmailSuppressionReason.Complaint &&
                suppression.Source == "SES" &&
                suppression.SourceEventId == "event-1" &&
                suppression.ProviderMessageId == "ses-message-2"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task TryProcessAsync_IgnoresNonSesEvents()
    {
        var processor = CreateProcessor();
        using var document = JsonDocument.Parse("""
            {
              "source": "aws.dynamodb",
              "detail-type": "DynamoDB Stream Record"
            }
            """);

        var processed = await processor.TryProcessAsync(document.RootElement, CancellationToken.None);

        Assert.False(processed);
        _suppressions.Verify(r => r.UpsertAsync(
            It.IsAny<EmailSuppression>(),
            It.IsAny<CancellationToken>()), Times.Never);
    }

    private SesEmailEventProcessor CreateProcessor() =>
        new(_suppressions.Object, NullLogger<SesEmailEventProcessor>.Instance);

    private static string SesEvent(string detailType, string detail) => $$"""
        {
          "id": "event-1",
          "source": "aws.ses",
          "detail-type": "{{detailType}}",
          "time": "2026-06-01T12:00:00Z",
          "detail": {{detail}}
        }
        """;
}
