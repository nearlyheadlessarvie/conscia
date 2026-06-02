using System.Net;
using System.Text.Json;
using Conscia.Application.Configuration;
using Conscia.CognitoCustomEmailSender;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using CognitoCustomEmailSenderHandler = Conscia.CognitoCustomEmailSender.CognitoCustomEmailSender;

namespace Conscia.Tests.Unit.Lambda;

public class CognitoCustomEmailSenderTests
{
    [Fact]
    public async Task HandleAsync_SignUp_SendsConfirmationCodeThroughBrevo()
    {
        HttpRequestMessage? capturedRequest = null;
        string? capturedBody = null;
        var sender = CreateSender(async request =>
        {
            capturedRequest = request;
            capturedBody = await request.Content!.ReadAsStringAsync();
            return new HttpResponseMessage(HttpStatusCode.Created);
        });

        await sender.HandleAsync(CreateEvent("CustomEmailSender_SignUp"), CancellationToken.None);

        Assert.NotNull(capturedRequest);
        Assert.Equal(HttpMethod.Post, capturedRequest!.Method);
        Assert.Equal(new Uri("https://api.brevo.com/v3/smtp/email"), capturedRequest.RequestUri);
        Assert.Equal("brevo-api-key", capturedRequest.Headers.GetValues("api-key").Single());

        using var document = JsonDocument.Parse(capturedBody!);
        var root = document.RootElement;
        Assert.Equal("no-reply@getconscia.com", root.GetProperty("sender").GetProperty("email").GetString());
        Assert.Equal("Conscia", root.GetProperty("sender").GetProperty("name").GetString());
        Assert.Equal("person@example.com", root.GetProperty("to")[0].GetProperty("email").GetString());
        Assert.Equal("Confirm your Conscia email", root.GetProperty("subject").GetString());
        Assert.Contains("123456", root.GetProperty("textContent").GetString());
        Assert.Contains("123456", root.GetProperty("htmlContent").GetString());
    }

    [Fact]
    public async Task HandleAsync_AdminCreateUser_SendsTemporaryPasswordThroughBrevo()
    {
        string? capturedBody = null;
        var sender = CreateSender(async request =>
        {
            capturedBody = await request.Content!.ReadAsStringAsync();
            return new HttpResponseMessage(HttpStatusCode.Created);
        }, decryptedCode: "Temp&lt;Pass&gt;123");

        await sender.HandleAsync(CreateEvent("CustomEmailSender_AdminCreateUser"), CancellationToken.None);

        using var document = JsonDocument.Parse(capturedBody!);
        var root = document.RootElement;
        Assert.Equal("Your Conscia temporary password", root.GetProperty("subject").GetString());
        Assert.Contains("Temp<Pass>123", root.GetProperty("textContent").GetString());
        Assert.Contains("Temp&lt;Pass&gt;123", root.GetProperty("htmlContent").GetString());
    }

    [Fact]
    public async Task HandleAsync_ThrowsWhenBrevoIsNotConfigured()
    {
        var sender = CreateSender(
            _ => Task.FromResult(new HttpResponseMessage(HttpStatusCode.Created)),
            options: new BrevoEmailOptions { SenderEmail = "no-reply@getconscia.com" });

        await Assert.ThrowsAsync<InvalidOperationException>(() =>
            sender.HandleAsync(CreateEvent("CustomEmailSender_SignUp"), CancellationToken.None));
    }

    [Fact]
    public async Task HandleAsync_ThrowsWhenBrevoRejectsEmail()
    {
        var sender = CreateSender(_ =>
            Task.FromResult(new HttpResponseMessage(HttpStatusCode.BadRequest)
            {
                Content = new StringContent("""{"message":"invalid sender"}""")
            }));

        await Assert.ThrowsAsync<HttpRequestException>(() =>
            sender.HandleAsync(CreateEvent("CustomEmailSender_SignUp"), CancellationToken.None));
    }

    private static CognitoCustomEmailSenderHandler CreateSender(
        Func<HttpRequestMessage, Task<HttpResponseMessage>> handler,
        string decryptedCode = "123456",
        BrevoEmailOptions? options = null)
    {
        var httpClient = new HttpClient(new RecordingHandler(handler))
        {
            BaseAddress = new Uri("https://api.brevo.com")
        };

        return new CognitoCustomEmailSenderHandler(
            httpClient,
            Options.Create(options ?? new BrevoEmailOptions
            {
                ApiKey = "brevo-api-key",
                SenderEmail = "no-reply@getconscia.com",
                SenderName = "Conscia"
            }),
            new FakeDecryptor(decryptedCode),
            NullLogger<CognitoCustomEmailSenderHandler>.Instance);
    }

    private static CognitoCustomEmailSenderEvent CreateEvent(string triggerSource) => new()
    {
        TriggerSource = triggerSource,
        UserPoolId = "us-east-1_example",
        UserName = "person@example.com",
        Request = new CognitoCustomEmailSenderRequest
        {
            Code = "encrypted-code",
            UserAttributes =
            {
                ["email"] = "person@example.com"
            }
        }
    };

    private sealed class FakeDecryptor(string code) : ICognitoCodeDecryptor
    {
        public string DecryptCode(string encryptedCode) => WebUtility.HtmlDecode(code);
    }

    private sealed class RecordingHandler(Func<HttpRequestMessage, Task<HttpResponseMessage>> handler) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) =>
            handler(request);
    }
}
