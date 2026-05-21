using Amazon.CognitoIdentityProvider;
using Amazon.CognitoIdentityProvider.Model;
using Conscia.Application.DTOs;
using Conscia.Application.Interfaces;
using Conscia.Domain.Entities;
using Conscia.Domain.Enums;
using Microsoft.Extensions.Configuration;

namespace Conscia.Infrastructure.Services;

public sealed class UserProvisioningService : IUserProvisioningService
{
    private readonly IAmazonCognitoIdentityProvider _cognito;
    private readonly IUserRepository _users;
    private readonly ISubscriptionAdminService _admin;
    private readonly string _userPoolId;

    public UserProvisioningService(
        IAmazonCognitoIdentityProvider cognito,
        IUserRepository users,
        ISubscriptionAdminService admin,
        IConfiguration configuration)
    {
        _cognito = cognito;
        _users = users;
        _admin = admin;
        _userPoolId = configuration["Auth:Cognito:UserPoolId"]
            ?? throw new InvalidOperationException("Auth:Cognito:UserPoolId not configured");
    }

    public async Task<AdminUserLookupResponse> ProvisionReviewerAsync(ProvisionReviewerAccountRequest request, CancellationToken ct = default)
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        var existing = await _users.GetByEmailAsync(normalizedEmail, ct);
        if (existing is not null)
        {
            return request.GrantLifetimePremium
                ? await _admin.GrantLifetimePremiumAsync(existing.Id, "reviewer-provisioning", request.Note, ct)
                : (await _admin.LookupByEmailAsync(normalizedEmail, ct))!;
        }

        var created = await _cognito.AdminCreateUserAsync(new AdminCreateUserRequest
        {
            UserPoolId = _userPoolId,
            Username = normalizedEmail,
            TemporaryPassword = request.TemporaryPassword,
            MessageAction = MessageActionType.SUPPRESS,
            UserAttributes =
            [
                new AttributeType { Name = "email", Value = normalizedEmail },
                new AttributeType { Name = "email_verified", Value = "true" }
            ]
        }, ct);

        var subject = created.User?.Attributes?.FirstOrDefault(a => a.Name == "sub")?.Value;
        if (!Guid.TryParse(subject, out var userId))
        {
            throw new InvalidOperationException("Provisioned Cognito user did not return a GUID sub.");
        }

        var user = new User
        {
            Id = userId,
            Email = normalizedEmail,
            EmailConfirmed = true,
            CreatedAt = DateTime.UtcNow
        };
        await _users.AddAsync(user, ct);
        await _users.AddIdentityAsync(new UserIdentity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Provider = AuthProvider.Email,
            ProviderSub = normalizedEmail,
            Role = UserIdentityRole.Member,
            CreatedAt = DateTime.UtcNow
        }, ct);

        return request.GrantLifetimePremium
            ? await _admin.GrantLifetimePremiumAsync(userId, "reviewer-provisioning", request.Note, ct)
            : (await _admin.LookupByEmailAsync(normalizedEmail, ct))!;
    }
}
