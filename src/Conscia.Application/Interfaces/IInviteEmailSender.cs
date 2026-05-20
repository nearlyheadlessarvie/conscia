namespace Conscia.Application.Interfaces;

public interface IInviteEmailSender
{
    Task SendFamilyInviteAsync(FamilyInviteEmailMessage message, CancellationToken ct = default);
}

public sealed record FamilyInviteEmailMessage(
    Guid InviteId,
    string RecipientEmail,
    string FamilySpaceName,
    string InviteLink,
    DateTime ExpiresAt);
