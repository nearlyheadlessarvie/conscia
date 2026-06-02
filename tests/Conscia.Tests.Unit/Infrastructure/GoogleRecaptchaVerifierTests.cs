using System.Net;
using System.Text;
using Conscia.Application.Interfaces;
using Conscia.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

namespace Conscia.Tests.Unit.Infrastructure;

public class GoogleRecaptchaVerifierTests
{
    [Fact]
    public async Task VerifyAsync_ValidAssessment_ReturnsTrue()
    {
        var handler = new CapturingHandler("""
            {
              "tokenProperties": {
                "valid": true,
                "action": "signup"
              },
              "riskAnalysis": {
                "score": 0.9
              }
            }
            """);
        var verifier = CreateVerifier(handler);

        var result = await verifier.VerifyAsync(new CaptchaVerificationRequest(
            "captcha-token",
            "android-site-key",
            "signup",
            "203.0.113.10",
            "test-agent"));

        Assert.True(result);
        Assert.Equal(HttpMethod.Post, handler.Request?.Method);
        Assert.Equal(
            "https://recaptchaenterprise.googleapis.com/v1/projects/conscia-prod/assessments?key=recaptcha-api-key",
            handler.Request?.RequestUri?.ToString());
        Assert.Contains("\"expectedAction\":\"signup\"", handler.RequestBody);
    }

    [Fact]
    public async Task VerifyAsync_UnknownSiteKey_ReturnsFalseWithoutCallingGoogle()
    {
        var handler = new CapturingHandler("{}");
        var verifier = CreateVerifier(handler);

        var result = await verifier.VerifyAsync(new CaptchaVerificationRequest(
            "captcha-token",
            "attacker-site-key",
            "signup",
            null,
            null));

        Assert.False(result);
        Assert.Null(handler.Request);
    }

    private static GoogleRecaptchaVerifier CreateVerifier(CapturingHandler handler)
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Recaptcha:ApiKey"] = "recaptcha-api-key",
                ["Recaptcha:ProjectId"] = "conscia-prod",
                ["Recaptcha:AllowedSiteKeys"] = "android-site-key,ios-site-key",
                ["Recaptcha:MinimumScore"] = "0.5"
            })
            .Build();

        return new GoogleRecaptchaVerifier(
            new HttpClient(handler)
            {
                BaseAddress = new Uri("https://recaptchaenterprise.googleapis.com")
            },
            configuration,
            NullLogger<GoogleRecaptchaVerifier>.Instance);
    }

    private sealed class CapturingHandler(string responseBody) : HttpMessageHandler
    {
        public HttpRequestMessage? Request { get; private set; }
        public string? RequestBody { get; private set; }

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            Request = request;
            RequestBody = request.Content is null
                ? null
                : await request.Content.ReadAsStringAsync(cancellationToken);

            return new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(responseBody, Encoding.UTF8, "application/json")
            };
        }
    }
}
