using System.Net;
using System.Text.Json;
using Conscia.Application.Configuration;
using Conscia.Application.Interfaces;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;

namespace Conscia.Tests.Unit.Infrastructure;

public class BrevoInviteEmailSenderTests
{
    [Fact]
    public async Task SendFamilyInviteAsync_PostsTransactionalEmailToBrevo()
    {
        HttpRequestMessage? capturedRequest = null;
        string? capturedBody = null;
        var sender = CreateSender(async request =>
        {
            capturedRequest = request;
            capturedBody = await request.Content!.ReadAsStringAsync();
            return new HttpResponseMessage(HttpStatusCode.Created);
        });

        var inviteId = Guid.Parse("11111111-1111-1111-1111-111111111111");

        await sender.SendFamilyInviteAsync(new FamilyInviteEmailMessage(
            inviteId,
            "wife@example.com",
            "Santos Household",
            "conscia://family-invite?inviteId=11111111-1111-1111-1111-111111111111",
            new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc)));

        Assert.NotNull(capturedRequest);
        Assert.Equal(HttpMethod.Post, capturedRequest!.Method);
        Assert.Equal(new Uri("https://api.brevo.com/v3/smtp/email"), capturedRequest.RequestUri);
        Assert.Equal("brevo-api-key", capturedRequest.Headers.GetValues("api-key").Single());
        Assert.Equal("application/json", capturedRequest.Content!.Headers.ContentType!.MediaType);

        using var document = JsonDocument.Parse(capturedBody!);
        var root = document.RootElement;
        Assert.Equal("invites@getconscia.com", root.GetProperty("sender").GetProperty("email").GetString());
        Assert.Equal("Conscia", root.GetProperty("sender").GetProperty("name").GetString());
        Assert.Equal("wife@example.com", root.GetProperty("to")[0].GetProperty("email").GetString());
        Assert.Equal("Family invite to Santos Household", root.GetProperty("subject").GetString());
        var textContent = root.GetProperty("textContent").GetString();
        Assert.Contains("You were invited to join Santos Household in Conscia.", textContent);
        Assert.Contains("conscia://family-invite?inviteId=11111111-1111-1111-1111-111111111111", textContent);
        Assert.Contains("This invite expires on June 1, 2026.", textContent);
        Assert.Contains("<h2>Family invite</h2>", root.GetProperty("htmlContent").GetString());
        Assert.Contains("Santos Household", root.GetProperty("htmlContent").GetString());
    }

    [Fact]
    public async Task SendFamilyInviteAsync_ThrowsWhenBrevoIsNotConfigured()
    {
        var sender = CreateSender(
            _ => Task.FromResult(new HttpResponseMessage(HttpStatusCode.Created)),
            new BrevoEmailOptions { SenderEmail = "invites@getconscia.com" });

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            sender.SendFamilyInviteAsync(CreateMessage()));
    }

    [Fact]
    public async Task SendFamilyInviteAsync_ThrowsWhenBrevoRejectsEmail()
    {
        var sender = CreateSender(_ =>
            Task.FromResult(new HttpResponseMessage(HttpStatusCode.BadRequest)
            {
                Content = new StringContent("""{"message":"invalid sender"}""")
            }));

        await Assert.ThrowsAsync<HttpRequestException>(() =>
            sender.SendFamilyInviteAsync(CreateMessage()));
    }

    private static BrevoInviteEmailSender CreateSender(
        Func<HttpRequestMessage, Task<HttpResponseMessage>> handler,
        BrevoEmailOptions? options = null)
    {
        var httpClient = new HttpClient(new RecordingHandler(handler))
        {
            BaseAddress = new Uri("https://api.brevo.com")
        };

        return new BrevoInviteEmailSender(
            httpClient,
            Options.Create(options ?? new BrevoEmailOptions
            {
                ApiKey = "brevo-api-key",
                SenderEmail = "invites@getconscia.com",
                SenderName = "Conscia"
            }),
            NullLogger<BrevoInviteEmailSender>.Instance);
    }

    private static FamilyInviteEmailMessage CreateMessage() => new(
        Guid.NewGuid(),
        "wife@example.com",
        "Santos Household",
        "conscia://family-invite",
        new DateTime(2026, 6, 1, 0, 0, 0, DateTimeKind.Utc));

    private sealed class RecordingHandler(Func<HttpRequestMessage, Task<HttpResponseMessage>> handler) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
            handler(request);
    }
}
