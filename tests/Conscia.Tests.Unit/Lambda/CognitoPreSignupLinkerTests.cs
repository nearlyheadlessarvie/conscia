using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using System.Text.Json;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using CognitoPreSignupEvent = Conscia.CognitoPreSignupLinker.CognitoPreSignupEvent;
using CognitoPreSignupLinkerHandler = Conscia.CognitoPreSignupLinker.CognitoPreSignupLinker;
using CognitoPreSignupRequest = Conscia.CognitoPreSignupLinker.CognitoPreSignupRequest;

namespace Conscia.Tests.Unit.Lambda;

public class CognitoPreSignupLinkerTests
{
    private readonly Mock<IAmazonCognitoIdentityProvider> _cognito = new();
    private readonly CognitoPreSignupLinkerHandler _linker;

    public CognitoPreSignupLinkerTests()
    {
        _linker = new CognitoPreSignupLinkerHandler(
            _cognito.Object,
            NullLogger<CognitoPreSignupLinkerHandler>.Instance);
    }

    [Fact]
    public async Task HandleAsync_TrustedGoogleSignInWithVerifiedEmail_LinksToExistingLocalUser()
    {
        var request = CreateRequest("PreSignUp_ExternalProvider", "Google_103448169750402666663");

        _cognito
            .Setup(client => client.ListUsersAsync(
                It.Is<ListUsersRequest>(r =>
                    r.UserPoolId == "ap-southeast-1_example" &&
                    r.Filter == "email = \"person@example.com\""),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ListUsersResponse
            {
                Users =
                [
                    new UserType { Username = "09fa25bc-1081-70e0-4ba1-3b56973d5000" }
                ]
            });

        await _linker.HandleAsync(request, CancellationToken.None);

        _cognito.Verify(client => client.AdminLinkProviderForUserAsync(
            It.Is<AdminLinkProviderForUserRequest>(r =>
                r.UserPoolId == "ap-southeast-1_example" &&
                r.DestinationUser.ProviderName == "Cognito" &&
                r.DestinationUser.ProviderAttributeValue == "09fa25bc-1081-70e0-4ba1-3b56973d5000" &&
                r.SourceUser.ProviderName == "Google" &&
                r.SourceUser.ProviderAttributeName == "Cognito_Subject" &&
                r.SourceUser.ProviderAttributeValue == "103448169750402666663"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task HandleAsync_NoLocalUser_CreatesSuppressedAnchorAndLinksProvider()
    {
        var request = CreateRequest("PreSignUp_ExternalProvider", "SignInWithApple_000644.989a6e2a48");

        _cognito
            .Setup(client => client.ListUsersAsync(
                It.Is<ListUsersRequest>(r =>
                    r.UserPoolId == "ap-southeast-1_example" &&
                    r.Filter == "email = \"person@example.com\""),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new ListUsersResponse { Users = [] });
        _cognito
            .Setup(client => client.AdminCreateUserAsync(
                It.Is<AdminCreateUserRequest>(r =>
                    r.UserPoolId == "ap-southeast-1_example" &&
                    r.Username == "person@example.com" &&
                    r.MessageAction == MessageActionType.SUPPRESS &&
                    r.UserAttributes.Any(a => a.Name == "email" && a.Value == "person@example.com") &&
                    r.UserAttributes.Any(a => a.Name == "email_verified" && a.Value == "true")),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(new AdminCreateUserResponse
            {
                User = new UserType { Username = "person@example.com" }
            });

        await _linker.HandleAsync(request, CancellationToken.None);

        _cognito.Verify(client => client.AdminLinkProviderForUserAsync(
            It.Is<AdminLinkProviderForUserRequest>(r =>
                r.UserPoolId == "ap-southeast-1_example" &&
                r.DestinationUser.ProviderName == "Cognito" &&
                r.DestinationUser.ProviderAttributeValue == "person@example.com" &&
                r.SourceUser.ProviderName == "SignInWithApple" &&
                r.SourceUser.ProviderAttributeName == "Cognito_Subject" &&
                r.SourceUser.ProviderAttributeValue == "000644.989a6e2a48"),
            It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task HandleAsync_UnverifiedEmail_DoesNotAttemptLinking()
    {
        var request = CreateRequest("PreSignUp_ExternalProvider", "Google_103448169750402666663");
        request.Request.UserAttributes["email_verified"] = "false";

        await _linker.HandleAsync(request, CancellationToken.None);

        _cognito.Verify(client => client.ListUsersAsync(It.IsAny<ListUsersRequest>(), It.IsAny<CancellationToken>()), Times.Never);
        _cognito.Verify(client => client.AdminLinkProviderForUserAsync(It.IsAny<AdminLinkProviderForUserRequest>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task HandleAsync_NonExternalTrigger_DoesNotAttemptLinking()
    {
        var request = CreateRequest("PreSignUp_SignUp", "person@example.com");

        await _linker.HandleAsync(request, CancellationToken.None);

        _cognito.Verify(client => client.ListUsersAsync(It.IsAny<ListUsersRequest>(), It.IsAny<CancellationToken>()), Times.Never);
        _cognito.Verify(client => client.AdminLinkProviderForUserAsync(It.IsAny<AdminLinkProviderForUserRequest>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task HandleAsync_RoundTripsCognitoCommonEventFields()
    {
        const string json = """
            {
              "version": "1",
              "triggerSource": "PreSignUp_SignUp",
              "region": "ap-southeast-1",
              "userPoolId": "ap-southeast-1_example",
              "userName": "person@example.com",
              "callerContext": {
                "awsSdkVersion": "aws-sdk-unknown-unknown",
                "clientId": "client-123"
              },
              "request": {
                "clientMetadata": {
                  "source": "local-test"
                },
                "validationData": null,
                "userAttributes": {
                  "email": "person@example.com",
                  "email_verified": "true"
                }
              },
              "response": {
                "autoConfirmUser": false,
                "autoVerifyEmail": false,
                "autoVerifyPhone": false
              }
            }
            """;
        var request = JsonSerializer.Deserialize<CognitoPreSignupEvent>(json)
            ?? throw new InvalidOperationException("Test event did not deserialize.");

        var result = await _linker.HandleAsync(request, CancellationToken.None);
        var responseJson = JsonSerializer.Serialize(result);
        using var document = JsonDocument.Parse(responseJson);
        var root = document.RootElement;

        Assert.Equal("1", root.GetProperty("version").GetString());
        Assert.Equal("ap-southeast-1", root.GetProperty("region").GetString());
        Assert.Equal(
            "client-123",
            root.GetProperty("callerContext").GetProperty("clientId").GetString());
        Assert.Equal(
            "local-test",
            root.GetProperty("request").GetProperty("clientMetadata").GetProperty("source").GetString());
        Assert.True(root.GetProperty("request").TryGetProperty("validationData", out _));
    }

    private static CognitoPreSignupEvent CreateRequest(string triggerSource, string userName)
    {
        return new CognitoPreSignupEvent
        {
            TriggerSource = triggerSource,
            UserPoolId = "ap-southeast-1_example",
            UserName = userName,
            Request = new CognitoPreSignupRequest
            {
                UserAttributes = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["email"] = "person@example.com",
                    ["email_verified"] = "true"
                }
            }
        };
    }
}
